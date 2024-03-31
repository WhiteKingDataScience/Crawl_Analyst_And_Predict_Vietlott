import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime
import pyodbc

# Kết nối đến SQL Server
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};'
                      'SERVER=WHITEKING\WHITEKING;'
                      'DATABASE=vietlott;'
                      'Trusted_Connection=yes;')

cursor = conn.cursor()

start_draw = int(input('Bạn muốn tải dữ liệu Vietlott Power 6/55 từ kỳ: '))
end_draw = int(input('đến kỳ: '))

drawID_series = [str(i).zfill(5) for i in range(start_draw, end_draw + 1)]

# Vòng lặp để tải dữ liệu về
for drawID in drawID_series:
    # URL của trang web cần crawl
    url = f'https://vietlott.vn/vi/trung-thuong/ket-qua-trung-thuong/655?id={drawID}&nocatche=1'


    # Gửi yêu cầu HTTP GET đến URL
    response = requests.get(url)

    # Sử dụng BeautifulSoup để phân tích cú pháp HTML
    soup = BeautifulSoup(response.text, 'html.parser')

    # Lấy giá trị ngày của dữ liệu
    h5_tag = soup.find('div', class_='chitietketqua_title').find('h5')
    date_str = h5_tag.find_all('b')[-1].text  # Lấy nội dung của thẻ <b> cuối cùng
    date_object = datetime.strptime(date_str, '%d/%m/%Y').date()

    ######### 1. Tải dữ liệu về số trúng giải #################

    # Tìm kiếm dữ liệu cần thiết
    # Ví dụ: tìm tất cả các thẻ <div> có class là 'some-class-name'
    draw_data = soup.find_all('div', class_='day_so_ket_qua_v2')

    # Lấy các kết quả trả về dưới dạng text
    for item in draw_data:
        draw = item.text
    # result = [item.text for item in draw_data]
    # Tách chuỗi thành phần số quả bóng và số đặc biệt
    balls, ball_special = draw.split('|')
    # Tách các số quả bóng
    ball_number = [balls[i:i+2] for i in range(1, len(balls), 2)]
    # Tạo dictionary
    draw_result = {'draw_ID': drawID, 'draw_date': date_object}
    draw_result.update({f'ball_{i+1}': ball_number[i] for i in range(len(ball_number))})
    draw_result['ball_special'] = ball_special
    # Tạo DataFrame từ dữ liệu và thêm vào danh sách
    draw_result = {key: [value] for key, value in draw_result.items()}
    df_draw_result = pd.DataFrame(draw_result)
    
    # Câu lệnh SQL để chèn dữ liệu vào table power.draw_result_power
    draw_result_query = '''
    MERGE INTO power.draw_result_power AS target
	USING (SELECT	  ? AS draw_ID
					, ? AS draw_date
					, ? AS ball_1
					, ? AS ball_2
					, ? AS ball_3
					, ? AS ball_4
					, ? AS ball_5
					, ? AS ball_6
					, ? AS ball_special
	) AS source
	ON target.draw_ID = source.draw_ID AND target.draw_date = source.draw_date
	WHEN MATCHED THEN
		UPDATE SET	target.ball_1 = source.ball_1, target.ball_2 = source.ball_2,
					target.ball_3 = source.ball_3, target.ball_4 = source.ball_4,
					target.ball_5 = source.ball_5, target.ball_6 = source.ball_6,
					target.ball_special = source.ball_special
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (draw_ID, draw_date, ball_1, ball_2, ball_3, ball_4, ball_5, ball_6, ball_special)
		VALUES (source.draw_ID, source.draw_date, source.ball_1, source.ball_2
				, source.ball_3, source.ball_4, source.ball_5, source.ball_6, source.ball_special);
    '''
    # Duyệt qua mỗi hàng trong DataFrame và insert vào SQL Server
    for index, row in df_draw_result.iterrows():
        cursor.execute(draw_result_query, row['draw_ID'], row['draw_date'], row['ball_1'], row['ball_2'], row['ball_3'], row['ball_4'], row['ball_5'], row['ball_6'], row['ball_special'])



    ############################################

    ######### 2. Tải dữ liệu giá trị và số lượng giải #################
    # Tìm kiếm dữ liệu cần thiết
    # Ví dụ: tìm tất cả các thẻ <div> có class là 'some-class-name'
    prize_data = soup.find('div', class_='table-responsive').find('table')
    # Trích xuất tiêu đề cột
    headers = []
    for th in prize_data.find('thead').find_all('th'):
        headers.append(th.text.strip())
    # Trích xuất dữ liệu hàng
    rows = []
    for tr in prize_data.find('tbody').find_all('tr'):
        cells = tr.find_all('td')
        row_data = [cell.text.strip() for cell in cells]
        rows.append(row_data)
    # Tạo DataFrame
    df_prize_result = pd.DataFrame(rows, columns=headers)
    # Bỏ cột "Kết quả"
    df_prize_result = df_prize_result.drop(columns=["Kết quả"])
    # Đổi tên các cột
    df_prize_result = df_prize_result.rename(columns={
        "Giải thưởng": "prize",
        "Số lượng giải": "number_of_prizes",
        "Giá trị giải (đồng)": "prize_value"
    })
    # Chuyển đổi định dạng của cột number_of_prizes và prize_value
    # Loại bỏ các dấu phân cách (ví dụ: dấu chấm đề phân cách hàng nghìn)
    df_prize_result["number_of_prizes"] = df_prize_result["number_of_prizes"].str.replace(".", "").astype(int)
    df_prize_result["prize_value"] = df_prize_result["prize_value"].str.replace(".", "").str.replace("đồng", "").astype('int64')
    df_prize_result['draw_ID'] = drawID
    df_prize_result['draw_date'] = date_object
    # Thay đổi các giá trị cột 'prize'
    df_prize_result['prize'] = df_prize_result['prize'].replace({
        'Giải Nhất': 'First prize',
        'Giải Nhì': 'Second prize',
        'Giải Ba': 'Third prize'
    })

    # Câu lệnh SQL để chèn dữ liệu vào table power.prize_result_power
    prize_result_query = '''
    MERGE INTO power.prize_result_power AS target
	USING (SELECT	  ? AS prize
					, ? AS number_of_prizes
					, ? AS prize_value
					, ? AS draw_ID
					, ? AS draw_date
	) AS source
	ON target.draw_ID = source.draw_ID AND target.draw_date = source.draw_date AND target.prize = source.prize
	WHEN MATCHED THEN
		UPDATE SET	target.number_of_prizes = source.number_of_prizes, target.prize_value = source.prize_value

	WHEN NOT MATCHED BY TARGET THEN
		INSERT (prize, number_of_prizes, prize_value, draw_ID, draw_date)
		VALUES (source.prize, source.number_of_prizes, source.prize_value
				, source.draw_ID, source.draw_date);
    '''
    # Duyệt qua mỗi hàng trong DataFrame và insert vào SQL Server
    for index, row in df_prize_result.iterrows():
        cursor.execute(prize_result_query, row['prize'], row['number_of_prizes'], row['prize_value'], row['draw_ID'], row['draw_date'])


# Cam kết giao dịch
conn.commit()

# Đóng kết nối
cursor.close()
conn.close()