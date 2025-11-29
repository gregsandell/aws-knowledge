#!/usr/bin/env node
/**
 * This code came from an AI request to translate create-starter-policy.sh to node.js.
 */
/**
 *
 * Usage:
 *   POLICY_FILE=necessary-policies.json \
 *   POLICY_NAME=starter-policies \
 *   TARGET_GROUP=aws-cli-capabilities \
 *   node manage-policy.js
 *
 * Dependencies:
 *   npm install @aws-sdk/client-iam inquirer chalk
 */

const { IAMClient,
    ListPoliciesCommand,
    CreatePolicyCommand,
    ListEntitiesForPolicyCommand,
    DetachGroupPolicyCommand,
    DeletePolicyCommand,
    AttachGroupPolicyCommand
} = require("@aws-sdk/client-iam");

const { paginateListPolicies } = require("@aws-sdk/client-iam");
const inquirer = require("inquirer");
const fs = require("fs").promises;
const chalk = require("chalk");

const POLICY_FILE = process.env.POLICY_FILE || "necessary-policies.json";
const POLICY_NAME = process.env.POLICY_NAME || "starter-policies";
const TARGET_GROUP = process.env.TARGET_GROUP || "aws-cli-capabilities";

const iam = new IAMClient({}); // uses env / profile credentials

async function ynquery(prompt) {
    const ans = await inquirer.prompt([
        {
            type: "confirm",
            name: "ok",
            message: prompt,
            default: false
        }
    ]);
    return ans.ok;
}

async function findLocalPolicyByName(policyName) {
    // Use paginator to collect all Local policies and find matches by name
    const paginator = paginateListPolicies({ client: iam }, { Scope: "Local" });
    const matches = [];
    for await (const page of paginator) {
        const policies = page.Policies || [];
        for (const p of policies) {
            if (p.PolicyName === policyName) matches.push(p);
        }
    }
    return matches; // array (zero, one, or more)
}

async function main() {
    console.log(chalk.cyan("Info:"));
    console.log(`This script will create (or clean up) policy ${chalk.bold(POLICY_NAME)} from file ${chalk.bold(POLICY_FILE)} and attach it to group ${chalk.bold(TARGET_GROUP)}.`);
    console.log(`${TARGET_GROUP} must already exist.`);
    console.log();

    console.log("Current status: checking whether a policy named", POLICY_NAME, "already exists...");
    const matches = await findLocalPolicyByName(POLICY_NAME);

    if (matches.length > 0) {
        // If multiple found, show them; otherwise single
        const policyArns = matches.map(p => p.Arn).join(", ");
        console.log();
        console.log(chalk.yellow("Found existing policy(ies):"));
        matches.forEach(p => {
            console.log(` - ${p.PolicyName}  ${p.Arn}  Path=${p.Path}  CreateDate=${p.CreateDate}`);
        });

        console.log();
        console.log(`Yes, a policy "${POLICY_NAME}" already exists with ARN(s): ${policyArns}`);
        const remove = await ynquery(`Remove the existing policy ${POLICY_NAME} and continue?`);
        if (!remove) {
            console.log("Ok, not removing policy. Goodbye.");
            process.exit(0);
        }

        console.log();
        console.log("Before removing, checking if it is attached to any entities...");
        // If there are multiple matching policies, ask user which ARN to operate on.
        let chosenArn;
        if (matches.length === 1) {
            chosenArn = matches[0].Arn;
        } else {
            const pick = await inquirer.prompt([
                {
                    type: "list",
                    name: "arn",
                    message: `Multiple policies named ${POLICY_NAME} found. Choose ARN to remove:`,
                    choices: matches.map(p => ({ name: `${p.Arn} (Path=${p.Path})`, value: p.Arn }))
                }
            ]);
            chosenArn = pick.arn;
        }

        // List entities for the chosen policy
        let entities;
        try {
            const resp = await iam.send(new ListEntitiesForPolicyCommand({ PolicyArn: chosenArn }));
            entities = resp || {};
        } catch (err) {
            console.error(chalk.red("Error listing entities for policy:"), err);
            process.exit(1);
        }

        const attachedGroups = (entities.PolicyGroups || []).map(g => g.GroupName);
        const attachedUsers = (entities.PolicyUsers || []).map(u => u.UserName);
        const attachedRoles = (entities.PolicyRoles || []).map(r => r.RoleName);

        if (attachedGroups.length || attachedUsers.length || attachedRoles.length) {
            console.log();
            console.log(chalk.yellow("Policy is attached to the following entities:"));
            if (attachedGroups.length) console.log("  Groups:", attachedGroups.join(", "));
            if (attachedUsers.length)  console.log("  Users: ", attachedUsers.join(", "));
            if (attachedRoles.length)  console.log("  Roles: ", attachedRoles.join(", "));
            console.log();

            const detachAll = await ynquery("Do you want to detach the policy from the listed entities now?");

            if (detachAll) {
                // Detach from groups
                for (const g of attachedGroups) {
                    console.log(`Detaching policy from group ${g}...`);
                    try {
                        await iam.send(new DetachGroupPolicyCommand({ GroupName: g, PolicyArn: chosenArn }));
                        console.log(chalk.green(` Detached from group ${g}`));
                    } catch (err) {
                        console.error(chalk.red(` Failed to detach from group ${g}:`), err);
                        process.exit(1);
                    }
                }
                // NOTE: If users/roles were attached, you'd detach them similarly (DetachUserPolicy / DetachRolePolicy).
                // For brevity, only group-detach is implemented here since original script handled groups.
                if (attachedUsers.length) {
                    for (const u of attachedUsers) {
                        console.log(`Policy is attached to user ${u}. Please detach manually or extend the script to call DetachUserPolicy.`);
                    }
                }
                if (attachedRoles.length) {
                    for (const r of attachedRoles) {
                        console.log(`Policy is attached to role ${r}. Please detach manually or extend the script to call DetachRolePolicy.`);
                    }
                }

                // After detaching, confirm deletion
                const confirmDelete = await ynquery(`Remove policy "${POLICY_NAME}" now?`);
                if (!confirmDelete) {
                    console.log("Ok, not deleting policy. Exiting.");
                    process.exit(0);
                }

                // Delete the policy (note: may need to delete non-default versions first; we attempt delete and surface error)
                try {
                    await iam.send(new DeletePolicyCommand({ PolicyArn: chosenArn }));
                    console.log(chalk.green(`Successfully deleted policy ${chosenArn}`));
                } catch (err) {
                    console.error(chalk.red("Failed to delete policy. You may need to remove non-default versions first. Error:"), err);
                    process.exit(1);
                }

            } else {
                console.log();
                const removeNow = await ynquery(`Remove policy "${POLICY_NAME}" from account now (without detaching)? Answering 'y' will attempt delete and likely fail if attachments remain.`);
                if (removeNow) {
                    try {
                        await iam.send(new DeletePolicyCommand({ PolicyArn: chosenArn }));
                        console.log(chalk.green(`Deleted policy ${chosenArn}`));
                    } catch (err) {
                        console.error(chalk.red("Delete failed (likely attachments or versions exist):"), err);
                        process.exit(1);
                    }
                } else {
                    console.log("Ok, not removing policy. Goodbye.");
                    process.exit(0);
                }
            }
        } else {
            // No attached entities: safe to delete
            const confirm = await ynquery(`Policy has no attachments. Delete policy "${POLICY_NAME}" now?`);
            if (!confirm) {
                console.log("Ok, not deleting policy. Goodbye.");
                process.exit(0);
            }
            try {
                await iam.send(new DeletePolicyCommand({ PolicyArn: chosenArn }));
                console.log(chalk.green(`Deleted policy ${chosenArn}`));
            } catch (err) {
                console.error(chalk.red("Delete failed:"), err);
                process.exit(1);
            }
        }

        // end of branch where policy existed & was removed (or not)
        process.exit(0);

    } else {
        // No existing policy found — create and attach
        console.log("No existing policy named", POLICY_NAME, "found. Proceeding to create it.");
        // Read file
        let doc;
        try {
            doc = await fs.readFile(POLICY_FILE, "utf8");
            // Validate JSON
            JSON.parse(doc);
        } catch (err) {
            console.error(chalk.red(`Error reading or parsing policy file ${POLICY_FILE}:`), err.message || err);
            process.exit(1);
        }

        // Create policy
        let arn;
        try {
            const resp = await iam.send(new CreatePolicyCommand({
                PolicyName: POLICY_NAME,
                PolicyDocument: doc
            }));
            arn = resp.Policy && resp.Policy.Arn;
            console.log(chalk.green("Created policy with ARN:"), arn);
        } catch (err) {
            console.error(chalk.red("Failed to create policy:"), err);
            process.exit(1);
        }

        // Attach to target group
        console.log();
        console.log(`Attaching policy ${POLICY_NAME} to group ${TARGET_GROUP} ...`);
        try {
            await iam.send(new AttachGroupPolicyCommand({
                GroupName: TARGET_GROUP,
                PolicyArn: arn
            }));
            console.log(chalk.green(`Successfully attached policy ${POLICY_NAME} to group ${TARGET_GROUP}`));
        } catch (err) {
            console.error(chalk.red(`Failed to attach policy ${POLICY_NAME} to group ${TARGET_GROUP}:`), err);
            process.exit(1);
        }

        process.exit(0);
    }
}

main().catch(err => {
    console.error(chalk.red("Fatal error:"), err);
    process.exit(1);
});
