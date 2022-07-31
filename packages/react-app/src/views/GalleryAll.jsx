import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";       




const DEBUG = true;

function GalleryAll({readContracts, address}) {
     
    //const [Qty, setQty] = useState(0);
    //const [Ids, setIds] = useState([]);
    //const [Qtys, setQtys] = useState([]);
    //const [Html, setHtml] = useState([]);

    const lastMintedTokenId = useContractReader(readContracts, "Chaotic1155", "LastMintedTokenId");
    if(DEBUG) console.log("lastMintedTokenId", lastMintedTokenId);
    //const image = useContractReader(readContracts, "Loogies1155", "renderTokenById", [1])
    //const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
   
    const myRef = useRef();
    useEffect(async () => {
      async function getTokenIds() {
        if(readContracts && readContracts.Chaotic1155 && lastMintedTokenId){
          
        if(lastMintedTokenId > 0){
          var html = '';
          for(var i = 1; i <= lastMintedTokenId; ++i) {


            var svg = await readContracts.Chaotic1155.GenerateSVGofTokenById(i);  
            var supply = await readContracts.Chaotic1155.totalSupply(i);
            var bal = await readContracts.Chaotic1155.balanceOf(address,i);
            var uri = await readContracts.Chaotic1155.uri(i);

            console.log("atob",atob(uri?.split(",")[1]))
            if(DEBUG)console.log("supply", supply?.toNumber())
            if(DEBUG)console.log("owned", bal?.toNumber())

            if(svg && supply && bal){
              if(DEBUG)console.log("svg", svg)
              html = '<div>' + html + svg + '</div>' 
              +'<div>supply:' + supply?.toNumber() + ' owned:' + bal + '</div>'
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
    <div style={{paddingTop: 50}}>
        <div ref={myRef} />

    </div>
    );
}

export default GalleryAll;