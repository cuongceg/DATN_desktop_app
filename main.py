import asyncio
import random
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MOCK_TRANSCRIPT = (
"Chào các em. "
"Hôm nay chúng ta sẽ nói về vấn đề đồng bộ hóa trong hệ điều hành. "
"Đây là một chủ đề rất quan trọng khi lập trình đa luồng và hệ thống thời gian thực. "
"Khi nhiều luồng cùng truy cập vào một tài nguyên, chúng ta cần cơ chế khóa để tránh xung đột dữ liệu. "
"Nếu không có khóa, kết quả ghi cuối cùng có thể bị sai hoặc không dự đoán được. "
"Khái niệm coarse-grained locking trong C thường được dùng để khóa toàn bộ cấu trúc dữ liệu lớn. "
"Cách làm này khá đơn giản, dễ cài đặt và dễ kiểm soát tính đúng đắn ban đầu. "
"Tuy nhiên, nhược điểm của nó là làm giảm hiệu năng song song khi số lượng luồng tăng lên. "
"Các luồng sẽ phải chờ đợi nhau quá lâu, kể cả khi chúng thao tác trên những phần dữ liệu khác nhau. "
"Để cải thiện, người ta có thể dùng fine-grained locking, tức là chia nhỏ phạm vi khóa theo từng vùng dữ liệu. "
"Kỹ thuật này tăng mức độ song song nhưng lại làm mã nguồn phức tạp hơn và khó debug hơn. "
"Ngoài ra, nếu thiết kế không cẩn thận, chúng ta có thể gặp deadlock khi hai hoặc nhiều luồng chờ khóa lẫn nhau. "
"Một vấn đề khác là starvation, khi một luồng bị trì hoãn quá lâu do không giành được khóa. "
"Vì vậy, khi thiết kế cơ chế đồng bộ, chúng ta cần cân bằng giữa tính đúng đắn, hiệu năng và độ phức tạp bảo trì. "
"Trong thực tế, nên đo đạc bằng benchmark thay vì chỉ suy đoán lý thuyết. "
"Các công cụ profiler sẽ giúp phát hiện điểm nghẽn và thời gian chờ khóa trong hệ thống. "
"Nếu khối lượng ghi thấp nhưng đọc cao, chúng ta có thể cân nhắc read-write lock để tối ưu. "
"Trong một số trường hợp đặc biệt, cấu trúc lock-free hoặc wait-free cũng là lựa chọn đáng cân nhắc. "
"Tuy nhiên, các kỹ thuật đó yêu cầu kiến thức sâu về atomic operation và mô hình bộ nhớ. "
"Tóm lại, không có một chiến lược khóa nào tốt nhất cho mọi bài toán. "
"Giải pháp tốt nhất luôn phụ thuộc vào đặc trưng dữ liệu, tần suất truy cập và mục tiêu hiệu năng của hệ thống."
)

@app.websocket("/ws/stt")
async def stt_stream(websocket: WebSocket):
    await websocket.accept()
    print("Client đã kết nối tới luồng STT!")
    
    chunks = MOCK_TRANSCRIPT.split(" ")
    
    try:
        for chunk in chunks:
            await websocket.send_text(chunk + " ")
            delay = random.uniform(0.2, 0.8)
            await asyncio.sleep(delay)
            
    except Exception as e:
        print(f"Kết nối bị đóng: {e}")
    finally:
        print("Luồng STT kết thúc.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)