#/usr/bin/env python
from sitcpy.rbcp import Rbcp

def main():
    print('====== Test start ======')
    rbcp = Rbcp()
    print('== Peripheral ==')
    print('write val', rbcp.write(0x4000_0000, 'abcd'))
    print('read val ', rbcp.read(0x4000_0008, 4))
    print('write val', rbcp.write(0x4000_0000, '\0\0\0\0'))
    print('read val ', rbcp.read(0x4000_0008, 4))
    print('== DDR4 ==')
    print('write val', rbcp.write(0x8000_0000, 'abcd'))
    print('read val ', rbcp.read(0x8000_0000, 4))
    print('write val', rbcp.write(0x8000_0000, '\0\0\0\0'))
    print('read val ', rbcp.read(0x8000_0008, 4))
    print('====== Test end ======')


if __name__ == '__main__':
    main()