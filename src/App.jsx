// src/App.jsx
import React, { useState, useRef } from 'react';
import axios from 'axios';
import './App.css';
import ImageBox from './components/ImageBox';

function App() {
  const [selectedFile, setSelectedFile] = useState(null); // 사용자가 선택한 파일
  const [previewUrl, setPreviewUrl] = useState(null);     // 원본 이미지 미리보기
  const [resultImage, setResultImage] = useState(null);   // 백엔드에서 받은 결과 이미지
  const [isLoading, setIsLoading] = useState(false);      // 분석 중 상태
  const [isDragging, setIsDragging] = useState(false);    // 드래그 상태 관리

  // 파일 입력을 프로그래밍 방식으로 클릭하기 위한 참조
  const fileInputRef = useRef(null);

  // 1. 파일 선택 이벤트 (버튼 클릭 또는 드롭 시 공통 사용)
  const handleFile = (file) => {
    if (file && file.type.startsWith('image/')) {
      setSelectedFile(file);
      setPreviewUrl(URL.createObjectURL(file)); // 브라우저 메모리에 임시 URL 생성
      setResultImage(null); // 새 파일 업로드 시 이전 결과 초기화
    } else {
      alert("이미지 파일만 업로드 가능합니다.");
    }
  };

  const handleFileChange = (event) => {
    handleFile(event.target.files[0]);
  };

  // --- [드래그 앤 드롭 및 클릭 이벤트 핸들러] ---
  const handleBoxClick = () => {
    // 원본 이미지 박스를 클릭하면 숨겨진 input을 클릭한 것과 같은 효과를 냅니다.
    fileInputRef.current.click();
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    // 드롭된 파일 가져오기
    const file = e.dataTransfer.files[0];
    handleFile(file);
  };
  // ------------------------------------------

  // 2. '객체 찾기' 버튼 클릭 이벤트
  const handleAnalyze = async () => {
    if (!selectedFile) {
      alert("이미지를 먼저 업로드해주세요!");
      return;
    }

    setIsLoading(true);

    const formData = new FormData();
    formData.append('file', selectedFile);

    try {
      const response = await axios.post('/api/predict', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.data.success) {
        setResultImage(response.data.image);
      }
    } catch (error) {
      console.error("분석 중 오류 발생:", error);
      alert("서버와 통신하는 중 오류가 발생했습니다.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="container">
      <h1>YOLO11 Segmentation 서비스</h1>
      <h2>sonarqube</h2>
      <h3>1.2.kbs</h3>


      {/* 숨겨진 파일 입력 창 */}
      <input
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        ref={fileInputRef}
        style={{ display: 'none' }}
      />

      {/* 이미지 출력 섹션 */}
      <div className="image-display-area">
        {/* 원본 이미지 박스 (클릭 및 드래그 앤 드롭 영역) */}
        <div
          onClick={handleBoxClick}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          style={{
            flex: 1,
            cursor: 'pointer',
            opacity: isDragging ? 0.6 : 1, // 드래그 중일 때 투명도 변화
            transition: 'opacity 0.2s'
          }}
          title="클릭하거나 이미지를 끌어다 놓으세요"
        >
          <ImageBox
            title={selectedFile ? "원본 이미지" : "원본 이미지 (클릭 또는 드래그)"}
            imageSrc={previewUrl}
          />
        </div>

        {/* 결과 이미지 박스 */}
        <div style={{ flex: 1 }}>
          <ImageBox title="분석 결과 (Segmentation Masking)" imageSrc={resultImage} />
        </div>
      </div>

      {/* 객체 찾기 버튼 (이미지가 있을 때만 아래에 표시) */}
      {selectedFile && (
        <div style={{ marginTop: '40px' }}>
          <button onClick={handleAnalyze} disabled={isLoading}>
            {isLoading ? "분석 중..." : "객체 찾기 (Segmentation)"}
          </button>
        </div>
      )}

      {isLoading && <p className="loading-text">YOLO11 모델이 이미지를 분석하고 있습니다...</p>}
    </div>
  );
}

export default App;