// src/components/ImageBox.jsx
import React from 'react';

const ImageBox = ({ title, imageSrc }) => {
  return (
    <div className="image-box">
      <h3>{title}</h3>
      {imageSrc ? (
        <img src={imageSrc} alt={title} />
      ) : (
        <div style={{ height: '200px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#999' }}>
          이미지가 없습니다.
        </div>
      )}
    </div>
  );
};

export default ImageBox;