#!/usr/bin/python
import numpy
import sys

def main(type):
    if type[1] != 'dfibs':
        f = open('./' + type[1] + '.txt')
        f_w = open('./' + type[1]  + '_processed.txt', 'a')
        result_list = []
        line = f.readline()
        while line:
            if line[:17] == '33:33:00:00:11:11':
                result_list.append(int(line[-3:], 16))
                f_w.write(str(int(line[-3:],16)) + '\n')
            line = f.readline()
        print result_list
        print numpy.mean(result_list)
        f.close()
        f_w.close()

    elif type[1] == 'dfibs':
        temp = []
        port1 = []

        f = open('./' + type[1] + '.txt')
        f_w = open('./' + type[1]  + '_processed.txt', 'a')
        result_list = []
        line = f.readline()
        while line:
            if line.split(',')[1] != '00:00:00:00:00:01\n':
                temp.append(line)
            line = f.readline()
        
        for line in temp:
            if line[0] == '1':
                port1.append(int(line.split(',')[1][-3:], 16))
                f_w.write(str(int(line.split(',')[1][-3:], 16)) + '\n')
            else:
                pass
        print numpy.mean(port1)
        f.close()
        f_w.close()

    else:
        print 'Invalid Input!'

if __name__ == '__main__':
    main(sys.argv)
