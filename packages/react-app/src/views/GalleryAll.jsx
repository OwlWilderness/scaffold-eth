import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";       




const DEBUG = true;

function GalleryAll({readContracts, address}) {
     
    const [Qty, setQty] = useState(0);
    const [Ids, setIds] = useState([]);
    const [Qtys, setQtys] = useState([]);
    const [Html, setHtml] = useState([]);

    const lastMintedTokenId = useContractReader(readContracts, "Loogies1155", "LastMintedTokenId");
    if(DEBUG) console.log("lastMintedTokenId", lastMintedTokenId);
    //const image = useContractReader(readContracts, "Loogies1155", "renderTokenById", [1])
    //const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
   
    const myRef = useRef();
    useEffect(async () => {
      async function getTokenIds() {
        if(readContracts && readContracts.Loogies1155 && lastMintedTokenId){
        //const result = useContractReader(readContracts, "Loogies1155", "GetTokenIdsForAddress", [address])
        //const result =  await readContracts.Loogies1155.GetTokenIdsForAddress(address);
          
        if(lastMintedTokenId > 0){
          var html = '';
          for(var i = 1; i <= lastMintedTokenId; ++i) {


            var svg = await readContracts.Loogies1155.renderTokenById(i);  
            var bal = await readContracts.Loogies1155.balanceOf(address, i);
            if(svg){
              if(DEBUG)console.log("svg", svg)
              html = html + '<svg width="300" height="300">' 
              + svg + '<text x="150" y="290" fill="purple">Id:' 
              + String(i) + '  Owned:' + String(bal?bal:0) + '</text></svg>'  
                
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
    },[readContracts, address, lastMintedTokenId]);

    return (
    <div>
        <div ref={myRef} />

    </div>
    );
}

export default GalleryAll;