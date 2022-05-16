import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="https://github.com/austintgriffith/scaffold-eth" target="_blank" rel="noopener noreferrer">
      <PageHeader
        title="🎈 BalloonSwap 🎈"
        subTitle="swapping fake ether for even faker balloon tokens since like two days ago"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
