import { ConsoleSqlOutlined } from "@ant-design/icons";
import { useContractReader } from "eth-hooks";
import { ethers } from "ethers";
import React, { useEffect, useRef } from "react";
import { Link } from "react-router-dom";       


function Gallery({readContracts, address}) {
    
    const result = useContractReader(readContracts, "Quanta", "GetTokenIdsForAddress", [address])
    const totalQty = result ? result[0].toString() : 0
    const tokenIds = result ? result[1] : []
    const tokenQtys = result ? result[2] : []

    console.log("totalQty", totalQty);
    console.log("tokenIds", tokenIds);
    console.log("tokenQty", tokenQtys);

    const image = useContractReader(readContracts, "Quanta", "renderTokenById", [1]);;
    const html = '<svg width="400" height="400">' + image + '</svg>'
    //console.log("html", html);
  
    const myRef = useRef();
    useEffect(() => {
      if (totalQty && totalQty > 0)  {
        for(var i=0; i<tokenIds.length;++i){
            var tokenId = tokenIds[i]
            if (tokenId = 0) break;
            var tokenQty = tokenQtys[i] 
            var image = useContractReader(readContracts, "Quanta", "renderTokenById", [tokenId]);
            console.log("tokenid", tokenId, "tokenQty", tokenQty)
        }
        myRef.current.innerHTML = html 
      }
    },[totalQty]);


    return (
    <div>
          
        <div ref={myRef} />

    </div>
    );
}

export default Gallery;