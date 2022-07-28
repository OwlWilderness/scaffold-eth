import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";       




const DEBUG = false;

function Gallery({readContracts, address, balance}) {
     
    const [Qty, setQty] = useState(0);
    const [Ids, setIds] = useState([]);
    const [Qtys, setQtys] = useState([]);
    const [Html, setHtml] = useState([]);

    const totBalance = useContractReader(readContracts, "Loogies1155", "GetTokenIdsForAddress", [address]);
    if(DEBUG) console.log("totBalance", totBalance);
    //const image = useContractReader(readContracts, "Loogies1155", "renderTokenById", [1])
    //const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
    
    const myRef = useRef();
    useEffect(async () => {
      async function getTokenIds() {
        if(readContracts && readContracts.Loogies1155 && address){
        //const result = useContractReader(readContracts, "Loogies1155", "GetTokenIdsForAddress", [address])
        //const result =  await readContracts.Loogies1155.GetTokenIdsForAddress(address);
          
        if(totBalance){
          if(DEBUG) console.log("result 0",totBalance[0].toNumber());
          if(DEBUG) console.log("result 1",totBalance[1].split(","));
          if(DEBUG) console.log("result 2",totBalance[2].split(","));

          setQty(totBalance[0])
          var Ids = totBalance[1].split(",")
          
          if(DEBUG) console.log("ids length", Ids.length);
          var html = '';
          for(var i = 0; i < Ids.length; ++i) {
            var tokenId = Ids[i];

            if(DEBUG) console.log("ID::",tokenId);
            if(tokenId > 0) {
              var svg = await readContracts.Loogies1155.renderTokenById(tokenId);  
              var bal = await readContracts.Loogies1155.balanceOf(address, tokenId);
              var hasGrown = await readContracts.Loogies1155.HasGrown(tokenId);
              var canGrow = false;
              if(!hasGrown){
                var getWordsForId = await readContracts.Loogies1155.GetWordsForId(address, tokenId);
                if(getWordsForId && getWordsForId[0] > 0){
                  canGrow = true;
                }
              }
              console.log("hasGrown", hasGrown);
              if(svg){
                if(DEBUG)console.log("svg", svg)
                html = html + '<svg width="300" height="300">' 
                + svg + '<text x="90" y="290" fill="purple">Id:' 
                + String(tokenId) + ' |  Owned:' + String(bal) 
                + ' | Can Grow: ' + String(canGrow) + '</text></svg>'  
                 
              }
            }
          }
          if(html && myRef && myRef.current) {
            if(DEBUG)console.log("html", html)
            myRef.current.innerHTML = html 
          }          
        }
      }    
    } 
    getTokenIds();
    },[readContracts, balance, totBalance]);

    return (
    <div>
        <div ref={myRef} />

    </div>
    );
}

export default Gallery;