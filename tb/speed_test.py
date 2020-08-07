#/usr/bin/env python
from sitcpy.rbcp import Rbcp
import numpy as np
from datetime import datetime

LENGTH = 2*2*(2**20)
PACKET_LEN = 128
ADDR_HEAD = 0x8000_0000

def write(rbcp, data):
    loop_num = int(len(data)/PACKET_LEN)
    for i in range(loop_num):
        rbcp.write(ADDR_HEAD + PACKET_LEN*i, data[i*PACKET_LEN:(i+1)*PACKET_LEN])
    rbcp.write(ADDR_HEAD+PACKET_LEN*loop_num, data[loop_num*PACKET_LEN:]) 


def read(rbcp, length):
    data_buf = bytearray(length)
    loop_num = int(length/PACKET_LEN)
    for i in range(loop_num):
        data_buf[i*PACKET_LEN:(i+1)*PACKET_LEN] = rbcp.read(ADDR_HEAD + PACKET_LEN*i, 128)
    data_buf[loop_num*PACKET_LEN:] = rbcp.read(ADDR_HEAD+PACKET_LEN*loop_num, length - 128*loop_num)
    return data_buf


def main():
    # Preparation
    rs = np.random.RandomState(0)
    test_pattern = rs.randint(256, size=LENGTH)
    test_str = bytes(test_pattern.tolist())

    print('====== Test start ======')
    
    rbcp = Rbcp()
    print('==== DDR4 ====')
    print('== Write start ==')
    dt_wr_st = datetime.now()
    write(rbcp, test_str)
    dt_wr_en = datetime.now()
    print('Time: ', dt_wr_en - dt_wr_st)
    print('== Write end ==')
    print('== Read start ==')
    dt_rd_st = datetime.now()
    ret_data = read(rbcp, len(test_str))
    dt_rd_en = datetime.now()
    print('Time: ', dt_rd_en - dt_rd_st)
    print('== Read end ==')

    print('== Consistency ==')
    print('check:', test_str == ret_data)
    print('====== Test end ======')


if __name__ == '__main__':
    main()