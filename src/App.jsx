// src/App.jsx
import React, { useState } from 'react';
import axios from 'axios';
import './App.css';
import ImageBox from './components/ImageBox';

function App() {
  const [selectedFile, setSelectedFile] = useState(null); // 사용자가 선택한 파일
  const [previewUrl, setPreviewUrl] = useState(null);     // 원본 이미지 미리보기
  const [resultImage, setResultImage] = useState(null);   // 백엔드에서 받은 결과 이미지
  const [isLoading, setIsLoading] = useState(false);      // 분석 중 상태

  // 1. 파일 선택 이벤트
  const handleFileChange = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedFile(file);
      setPreviewUrl(URL.createObjectURL(file)); // 브라우저 메모리에 임시 URL 생성
      setResultImage(null); // 새 파일 업로드 시 이전 결과 초기화
    }
  };

  // 2. '객체 찾기' 버튼 클릭 이벤트 (백엔드 연동 부분)
  const handleAnalyze = async () => {
    if (!selectedFile) {
      alert("이미지를 먼저 업로드해주세요!");
      return;
    }

    setIsLoading(true);

    // FormData 객체 생성 (파일 전송용)
    const formData = new FormData();
    formData.append('file', selectedFile);

    try {
      // 백엔드 주소 (8000포트)로 요청을 보냅니다.
      const response = await axios.post('/api/predict', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.data.success) {
        // 백엔드에서 받은 Base64 이미지를 결과 창에 설정
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

      {/* 업로드 섹션 */}
      <div className="upload-section">
        <input
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          id="file-input"
          style={{ display: 'none' }}
        />
        <label htmlFor="file-input">
          <button onClick={() => document.getElementById('file-input').click()}>
            이미지 선택하기
          </button>
        </label>

        {selectedFile && (
          <div>
            <p>선택된 파일: {selectedFile.name}</p>
            <button onClick={handleAnalyze} disabled={isLoading}>
              {isLoading ? "분석 중..." : "객체 찾기 (Segmentation)"}
            </button>
          </div>
        )}
      </div>

      {/* 이미지 출력 섹션 */}
      <div className="image-display-area">
        <ImageBox title="원본 이미지" imageSrc={previewUrl} />
        <ImageBox title="분석 결과 (Segmentation Masking)" imageSrc={resultImage} />
      </div>

      {isLoading && <p className="loading-text">YOLO11 모델이 이미지를 분석하고 있습니다...</p>}
    </div>
  );
}

export default App;