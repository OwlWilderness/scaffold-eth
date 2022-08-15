import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";       
import { List, Card, Button } from "antd";



//const yourBalance = balance && balance.toNumber && balance.toNumber();
const DEBUG = false;

function GalleryAll({readContracts, address, balance, writeContracts, tx, all, price}) {
     
    //const [Qty, setQty] = useState(0);
    //const [Ids, setIds] = useState([]);
    //const [Qtys, setQtys] = useState([]);
    //const [Html, setHtml] = useState([]);

    const lastMintedTokenId = useContractReader(readContracts, "Chaotic1155", "LastMintedTokenId");
    const totalSupply = useContractReader(readContracts, "Chaotic1155", "TotalSupply");

    if(DEBUG) console.log("lastMintedTokenId", lastMintedTokenId);
    if(DEBUG) console.log("totalSupply", totalSupply);
    //const image = useContractReader(readContracts, "Loogies1155", "renderTokenById", [1])
    //const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
   
    const [yourCollectibles, setYourCollectibles] = useState();
    const [stakeAmount, setStakeAmount] = useState({});
    const [mintAmount, setMintAmount] = useState({});
    const [mintCost, setMintCost] = useState({})

    useEffect(() => {
      const updateYourCollectibles = async () => {
        const collectibleUpdate = [];
        for (let tokenIndex = 1; tokenIndex <= lastMintedTokenId; tokenIndex++) {
          try {
            if(DEBUG)console.log("GEtting token index", tokenIndex);
            //const tokenId = await readContracts.YourCollectible.tokenOfOwnerByIndex(address, tokenIndex);
            //console.log("tokenId", tokenId);
            const tokenURI = await readContracts.Chaotic1155.uri(tokenIndex);
            const jsonManifestString = atob(tokenURI.substring(29))
            if(DEBUG)console.log("jsonManifestString", jsonManifestString);

            const staked = await readContracts.ChaoticStaker.GetStaked4Account(address,tokenIndex);
            var supply = await readContracts.Chaotic1155.totalSupply(tokenIndex);
            var bal = await readContracts.Chaotic1155.balanceOf(address,tokenIndex);
            if(DEBUG)console.log("supply", supply?.toNumber())
            if(DEBUG)console.log("owned", bal?.toNumber())
  /*
            const ipfsHash = tokenURI.replace("https://ipfs.io/ipfs/", "");
            console.log("ipfsHash", ipfsHash);
            const jsonManifestBuffer = await getFromIPFS(ipfsHash);
          */
            if(all || bal>0){
              try {
                const jsonManifest = JSON.parse(jsonManifestString);
                if(DEBUG)console.log("jsonManifest", jsonManifest);
                collectibleUpdate.push({ id: tokenIndex, uri: tokenURI, owned: bal, supply: supply, staked: staked, ...jsonManifest });
              } catch (e) {
                console.log(e);
              }
            }
          } catch (e) {
            console.log(e);
          }
        }
        setYourCollectibles(collectibleUpdate.reverse());
      };
      updateYourCollectibles();
    }, [readContracts, address, balance, lastMintedTokenId, totalSupply]);

    return(
    <div style={{ width:"auto",  margin: "auto", paddingBottom: 256 }}>
    <List
      bordered
      dataSource={yourCollectibles}
      itemLayout="horizontal"
      size="small"
      grid={{
        gutter: 16,
        column: 4,
      }}      
      pagination={{
        onChange: (page) => {
          console.log(page);
        },
        pageSize: 8,
      }}      
      renderItem={item => {
        //console.log("item", item.id)
        const id = item.id;

       if(DEBUG)console.log("IMAGE",item.image)

        return (

          <List.Item key={String(item.id) + "_" + item.uri}>
            <Card
              title={
                <div>
                  <span style={{ fontSize: 18, marginRight: 8 }}>{item.name}</span>
                </div>
              }
            >
              <a href={"https://testnets.opensea.io/assets/mumbai/"+(readContracts && readContracts.Chaotic1155 && readContracts.Chaotic1155.address)+"/"+String(item.id)} target="_blank">
              <img src={item.image} />
              </a>
          
              <div>{'Supply:' + String(item.supply) + ' Owned:' + String(item.owned) + ' Staked:' + String(item.staked)} </div>
              <div>
                <input onChange={(e) => {
                            const update = {};
                            update[id] = e.target.value;
                            const cost = {}
                            cost[id] = price * e.target.value
                            setMintAmount({ ...mintAmount, ...update });
                            setMintCost({...mintCost, ...cost});
                         }} value={mintAmount[id]} type={"string"} placeholder="amount to mint"></input>
                <Button style={{marginTop:10, marginLeft:10}} type={"primary"} 
                    onClick={() => {
                      const mAmt = mintAmount[id]?mintAmount[id]:0
                      const mCost = mintCost[id]?mintCost[id]:0
                      tx(writeContracts.Chaotic1155.mint(address, id, mAmt, {value: mCost})); 
                    }}>Mint More ({mintCost[id] && String(parseFloat(ethers.utils.formatEther(mintCost[id])).toFixed(18) )})</Button>                
              </div>
              <div>
                <input onChange={(e) => {
                            const update = {};
                            update[id] = e.target.value;
                            setStakeAmount({ ...stakeAmount, ...update });
                         }} value={stakeAmount[id]} type={"string"} placeholder="amount to stake"></input>
                <Button style={{marginTop:10, marginLeft:10}} type={"primary"} 
                    onClick={() => {
                      const sAmt = stakeAmount[id]?stakeAmount[id]:0
                      tx(writeContracts.ChaoticStaker.Stake(id, sAmt)); 
                    }}>Stake</Button>

                <Button style={{marginTop:10, marginLeft:10}} type={"primary"} 
                    onClick={() => {
                      tx(writeContracts.ChaoticStaker.Unstake(id)); 
                    }}>Unstake ALL</Button>
              </div>
            </Card>
            </List.Item>  

        );
      }}
    />
  </div>    );
}

export default GalleryAll;