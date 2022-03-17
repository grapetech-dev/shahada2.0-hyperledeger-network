/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Contract } = require('fabric-contract-api');

const Web3 = require('web3');
let web3 = new Web3();
var md5 = require('md5');


class AssetTransfer extends Contract {

    async InitLedger(ctx) {
        const assets = [
            {
                ID: 'asset1',
                Color: 'blue',
                Size: 5,
                Owner: 'Tomoko',
                AppraisedValue: 300,
            },
            {
                ID: 'asset2',
                Color: 'red',
                Size: 5,
                Owner: 'Brad',
                AppraisedValue: 400,
            },
            {
                ID: 'asset3',
                Color: 'green',
                Size: 10,
                Owner: 'Jin Soo',
                AppraisedValue: 500,
            },
            {
                ID: 'asset4',
                Color: 'yellow',
                Size: 10,
                Owner: 'Max',
                AppraisedValue: 600,
            },
            {
                ID: 'asset5',
                Color: 'black',
                Size: 15,
                Owner: 'Adriana',
                AppraisedValue: 700,
            },
            {
                ID: 'asset6',
                Color: 'white',
                Size: 15,
                Owner: 'Michel',
                AppraisedValue: 800,
            },
        ];

        for (const asset of assets) {
            asset.docType = 'asset';
            await ctx.stub.putState(asset.ID, Buffer.from(JSON.stringify(asset)));
            console.info(`Asset ${asset.ID} initialized`);
        }
    }

    // CreateAsset issues a new asset to the world state with given details.
    async CreateAsset(ctx, id, color, size, owner, appraisedValue) {
        const asset = {
            ID: id,
            Color: color,
            Size: size,
            Owner: owner,
            AppraisedValue: appraisedValue,
        };
        ctx.stub.putState(id, Buffer.from(JSON.stringify(asset)));
        return JSON.stringify(asset);
    }

    // ReadAsset returns the asset stored in the world state with given id.
    async ReadAsset(ctx, id) {
        const assetJSON = await ctx.stub.getState(id); // get the asset from chaincode state
        if (!assetJSON || assetJSON.length === 0) {
            throw new Error(`The asset ${id} does not exist`);
        }
        return assetJSON.toString();
    }

    // UpdateAsset updates an existing asset in the world state with provided parameters.
    async UpdateAsset(ctx, id, color, size, owner, appraisedValue) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }

        // overwriting original asset with new asset
        const updatedAsset = {
            ID: id,
            Color: color,
            Size: size,
            Owner: owner,
            AppraisedValue: appraisedValue,
        };
        return ctx.stub.putState(id, Buffer.from(JSON.stringify(updatedAsset)));
    }

    // DeleteAsset deletes an given asset from the world state.
    async DeleteAsset(ctx, id) {
        const exists = await this.AssetExists(ctx, id);
        if (!exists) {
            throw new Error(`The asset ${id} does not exist`);
        }
        return ctx.stub.deleteState(id);
    }

    // AssetExists returns true when asset with given ID exists in world state.
    async AssetExists(ctx, id) {
        const assetJSON = await ctx.stub.getState(id);
        return assetJSON && assetJSON.length > 0;
    }

    // TransferAsset updates the owner field of asset with given id in the world state.
    async TransferAsset(ctx, id, newOwner) {
        const assetString = await this.ReadAsset(ctx, id);
        const asset = JSON.parse(assetString);
        asset.Owner = newOwner;
        return ctx.stub.putState(id, Buffer.from(JSON.stringify(asset)));
    }

    // GetAllAssets returns all assets found in the world state.
    async GetAllAssets(ctx) {
        const allResults = [];
        // range query with empty string for startKey and endKey does an open-ended query of all assets in the chaincode namespace.
        const iterator = await ctx.stub.getStateByRange('', '');
        let result = await iterator.next();
        while (!result.done) {
            const strValue = Buffer.from(result.value.value.toString()).toString('utf8');
            let record;
            try {
                record = JSON.parse(strValue);
            } catch (err) {
                console.log(err);
                record = strValue;
            }
            allResults.push({ Key: result.value.key, Record: record });
            result = await iterator.next();
        }
        return JSON.stringify(allResults);
    }

	    async putPrivateDataForEnrollment(ctx, msp, hashKey, recipientData) {

        let creator = await ctx.stub.getCreator();

          console.log("creator", creator);

        ctx.stub.putPrivateData("_implicit_org_" + msp, hashKey, Buffer.from(recipientData));

        ctx.stub.setEvent("PrivateDataAddedForEnrollment", Buffer.from(JSON.stringify([hashKey, creator])));

        return true;
    }

	async CreateIdentity(ctx, hash, EntityMSP) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        let identityData = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, hash);

		   identityData = identityData.toString();

        identityData = JSON.parse(identityData);
        console.log("identityData", identityData);

        //if (!identityData || identityData.length === 0) {
          //  throw new Error(`The identity Data does not exist in ` + creator.mspid + ' private collection ');
        //}

        let doc = identityData.document;

        let or = [];

        for (let i = 0; i < doc.length; i++) {
            or.push({"id_type": doc[i]['id_type'], "id_number": doc[i]['id_number']})
        }


          let queryString = {
            "selector": {
                "document": {
                    "$elemMatch": {
                        "$or": or
                    }
                }
            }
        };
	console.log("queryString",queryString);

        let findExisting = await this.GetQueryResultForQueryString1(ctx, JSON.stringify(queryString));

        console.log("findExisting", findExisting);

        findExisting = JSON.parse(findExisting);

        console.log("findExisting length", findExisting.length);


        if (findExisting.length === 0) {

            let acct = web3.eth.accounts.create();

            identityData.address = acct.address;
            identityData.privateKey = acct.privateKey;
            identityData['docType'] = "IdentityData";
            identityData['hashKey'] = md5(identityData);

console.log("new",identityData)
            await ctx.stub.putState(identityData['hashKey'], Buffer.from(JSON.stringify(identityData)));

           await ctx.stub.putPrivateData("_implicit_org_" + EntityMSP, hash, Buffer.from(JSON.stringify(identityData)));

           await ctx.stub.setEvent("IdentityCreated", Buffer.from(JSON.stringify([hash, identityData.address, "NewCreated"])))

        } else {
           console.log("old",identityData)
 //          await ctx.stub.putPrivateData("_implicit_org_" + EntityMSP, hash, Buffer.from(JSON.stringify(findExisting[0])));

   //          await ctx.stub.setEvent("IdentityCreated", Buffer.from(JSON.stringify([hash, identityData.address, "Existing"])))
  await ctx.stub.putPrivateData("_implicit_org_" + EntityMSP, hash, Buffer.from(JSON.stringify(findExisting[0]['Record'])));

            await ctx.stub.setEvent("IdentityCreated", Buffer.from(JSON.stringify([hash, findExisting[0]['Record']['address'], "Existing"])));
        }

        return true;


    }

    async GetAllResults1(iterator, isHistory) {
        let allResults = [];
        let res = await iterator.next();
        while (!res.done) {
            if (res.value && res.value.value.toString()) {
                let jsonRes = {};
                console.log(res.value.value.toString('utf8'));
                if (isHistory && isHistory === true) {
                    jsonRes.TxId = res.value.tx_id;
                    jsonRes.Timestamp = res.value.timestamp;
                    try {
                        jsonRes.Value = JSON.parse(res.value.value.toString('utf8'));
                    } catch (err) {
                        console.log(err);
                        jsonRes.Value = res.value.value.toString('utf8');
                    }
                } else {
                    jsonRes.Key = res.value.key;
                    try {
                        jsonRes.Record = JSON.parse(res.value.value.toString('utf8'));
                    } catch (err) {
                        console.log(err);
                        jsonRes.Record = res.value.value.toString('utf8');
                    }
                }
                allResults.push(jsonRes);
            }
            res = await iterator.next();
        }
        iterator.close();
        return allResults;
    }


    async GetQueryResultForQueryString1(ctx, queryString) {

        let resultsIterator = await ctx.stub.getQueryResult(queryString);
        let results = await this.GetAllResults1(resultsIterator, false);

        return JSON.stringify(results);
    }

	    async getPublicKeyForEnrollment(ctx, hashKey) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        let data = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, hashKey);

        data = data.toString();
        console.log("data",data);

        //data = JSON.parse(data);

        return data;
    }

	  async addRoleAudit(ctx, roleID, entityId, auditJson) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        auditJson = JSON.parse(auditJson);
        auditJson.docType='roleAudit';
        await ctx.stub.putPrivateData("_implicit_org_" + creator.mspid, roleID + entityId, Buffer.from(JSON.stringify(auditJson)));

        return true;
    }

	async addAuditForProcessFlow1(ctx, version, entityId, groupId, auditJson) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator);

        auditJson = JSON.parse(auditJson);

        auditJson.docType='processFlowAudit';

        await ctx.stub.putPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId, Buffer.from(JSON.stringify(auditJson)));

        return true;
    }
  async addMerkle(ctx, key, merkleRoot) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        ctx.stub.putState(key, Buffer.from(JSON.stringify({merkleRoot: merkleRoot})));

        return true;
    }

	async getMerkle(ctx, key) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        let data = await  ctx.stub.getState(key);

        data = data.toString();

        return data;

    }

	 // add process flow data
    async addProcessFlow1(ctx, version, entityId, groupId, process) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        process = JSON.parse(process);

        process.docType = 'processFlow';

        await ctx.stub.putPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId, Buffer.from(JSON.stringify(process)));

        return true;
    }

    // validate process flow data
    async validateProcessFlow1(ctx, version, entityId, groupId, action, roleId) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);


        let p = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId);

        p = p.toString();
        console.log("[validateProcessFlow] :", p)
        if (p.length === 0) {
            console.log("[validateProcessFlow] : No data found");
            return {isAllowed: false, msg: "No data found"};
        } else {

            if (action === 'Create') {
                if (p.creator === roleId) {
                    return {isAllowed: true, msg: "Success"};
                } else {
                    return {isAllowed: false, msg: "Success"};
                }
            } else if (action === 'Publish') {
                if (p.publisher === roleId) {
                    return {isAllowed: true, msg: "Success"};
                } else {
                    return {isAllowed: false, msg: "Success"};
                }
            } else {
                let v = 0;
                for (let i = 0; i < p.process.length; i++) {
                    if (p[i].action === action && p[i].auditor_role === roleId) {
                        v = 1;
                    }
                }
                if (v === 1) {
                    return {isAllowed: true, msg: "Success"};
                } else {
                    return {isAllowed: false, msg: "Success"};
                }
            }
        }
    }

	async validateProcessFlow2(ctx, version, entityId, groupId, action, roleId) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);


        let p = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + 'processFlow');

        p = p.toString();
        console.log("[validateProcessFlow] :", p)
        if (p.length === 0) {
            console.log("[validateProcessFlow] : No data found");
            return ({isAllowed: false, msg: "No data found"}).toString();
        } else {

            if (action === 'Create') {
                if (p.creator === roleId) {
                    return ({isAllowed: true, msg: "Success"}).toString();
                } else {
                    return ({isAllowed: false, msg: "Success"}).toString();
                }
            } else if (action === 'Publish') {
                if (p.publisher === roleId) {
                    return ({isAllowed: true, msg: "Success"}).toString();
                } else {
                    return ({isAllowed: false, msg: "Success"}).toString();
                }
            } else {
                let v = 0;
                for (let i = 0; i < p.process.length; i++) {
                    if (p[i].action === action && p[i].auditor_role === roleId) {
                        v = 1;
                    }
                }
                if (v === 1) {
                    return ({isAllowed: true, msg: "Success"}).toString();
                } else {
                    return ({isAllowed: false, msg: "Success"}).toString();
                }
            }
        }
    }

	async validateProcessFlow33(ctx, version, entityId, groupId, action, roleId) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);


        let p = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + 'processFlow');

        p = p.toString();
        console.log("[validateProcessFlow] :", p)
        if (p.length === 0) {
            console.log("[validateProcessFlow] : No data found");
            return JSON.stringify({isAllowed: false, msg: "No data found"});
        } else {

            if (action === 'Create') {
                if (p.creator === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else if (action === 'Publish') {
                if (p.publisher === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else {
                let v = 0;
                for (let i = 0; i < p.process.length; i++) {
                    if (p[i].action === action && p[i].auditor_role === roleId) {
                        v = 1;
                    }
                }
                if (v === 1) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            }
        }
    }

	    async addAuditForProcessFlow(ctx, version, entityId, groupId, auditJson) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator);

        auditJson = JSON.parse(auditJson);

        auditJson.docType = 'processFlowAudit';

        await ctx.stub.putPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + auditJson.docType, Buffer.from(JSON.stringify(auditJson)));

        return true;
    }

	    async addProcessFlow(ctx, version, entityId, groupId, process) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);

        process = JSON.parse(process);

        process.docType = 'processFlow';

        await ctx.stub.putPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + process.docType, Buffer.from(JSON.stringify(process)));

        return true;
    }

	   async validateProcessFlow22(ctx, version, entityId, groupId, action, roleId) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);


        let p = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + 'processFlow');

        p = p.toString();
        console.log("[validateProcessFlow] :", p)
        if (p.length === 0) {
            console.log("[validateProcessFlow] : No data found");
            return JSON.stringify({isAllowed: false, msg: "No data found"});
        } else {
            p = JSON.parse(p);
            if (action === 'Create') {
                if (p.creator === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else if (action === 'Publish') {
                if (p.publisher === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else {
                let v = 0;
                for (let i = 0; i < p.process.length; i++) {
                    if (p[i].action === action && p[i].auditor_role === roleId) {
                        v = 1;
                    }
                }
                if (v === 1) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            }
        }
    }

	 async validateProcessFlow(ctx, version, entityId, groupId, action, roleId) {

        let creator = await ctx.stub.getCreator();

        console.log("creator", creator.mspid);


        let p = await ctx.stub.getPrivateData("_implicit_org_" + creator.mspid, version + entityId + groupId + 'processFlow');

        p = p.toString();
        console.log("[validateProcessFlow] :", p)
        if (p.length === 0) {
            console.log("[validateProcessFlow] : No data found");
            return JSON.stringify({isAllowed: false, msg: "No data found"});
        } else {
            p = JSON.parse(p);
            if (action === 'Create') {
                if (p.creator === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else if (action === 'Publish') {
                if (p.publisher === roleId) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            } else {
                let v = 0;
                for (let i = 0; i < p.process.length; i++) {
                    if (p.process[i].action === action && p.process[i].auditor_role === roleId) {
                        v = 1;
                    }
                }
                if (v === 1) {
                    return JSON.stringify({isAllowed: true, msg: "Success"});
                } else {
                    return JSON.stringify({isAllowed: false, msg: "Success"});
                }
            }
        }
    }



}

module.exports = AssetTransfer;
