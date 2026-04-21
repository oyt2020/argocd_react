import React from 'react';

const ImageBox = ({ title, imageSrc }) => {
  return (
    <div className="image-box">
      <h3>{title}</h3>
      {imageSrc ? (
        <img src={imageSrc} alt={title} />
      ) : (
        <div className="empty-state">
          <p>이미지가 없습니다.</p>
        </div>
      )}
    </div>
  );
};

export default ImageBox;