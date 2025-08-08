import os
import subprocess
import threading
import queue
import argparse
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 支持的扩展名映射
CONVERSION_MAP = {
    '.png': ('.webp', 'ffmpeg -i "{input}" -compression_level 6 "{output}"'),
    '.ogg': ('.mp3', 'ffmpeg -i "{input}" -codec:a libmp3lame -qscale:a 2 "{output}"')
}

def convert_file(input_path, output_path, command):
    """转换单个文件"""
    try:
        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # 执行转换命令
        subprocess.run(
            command.format(input=input_path, output=output_path),
            shell=True,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        
        # 验证输出文件
        if not os.path.exists(output_path) or os.path.getsize(output_path) == 0:
            raise RuntimeError("输出文件创建失败")
        
        # 删除原始文件
        os.remove(input_path)
        logger.info(f"转换成功并删除源文件: {input_path} -> {output_path}")
        return True
    except Exception as e:
        logger.error(f"转换失败 {input_path}: {str(e)}")
        return False

def worker(task_queue):
    """工作线程函数"""
    while True:
        try:
            file_path = task_queue.get_nowait()
        except queue.Empty:
            return
            
        ext = os.path.splitext(file_path)[1].lower()
        if ext not in CONVERSION_MAP:
            return
            
        new_ext, command_template = CONVERSION_MAP[ext]
        output_path = os.path.splitext(file_path)[0] + new_ext
        
        # 处理已存在的输出文件
        if os.path.exists(output_path):
            try:
                # 直接删除源文件
                os.remove(file_path)
                logger.info(f"跳过转换（输出文件已存在），已删除源文件: {file_path}")
            except Exception as e:
                logger.error(f"删除源文件失败 {file_path}: {str(e)}")
            task_queue.task_done()
            continue
            
        convert_file(file_path, output_path, command_template)
        task_queue.task_done()

def find_files(root_dir):
    """查找所有需要转换的文件"""
    supported_exts = tuple(CONVERSION_MAP.keys())
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith(supported_exts):
                yield os.path.join(dirpath, filename)

def main():
    parser = argparse.ArgumentParser(description='批量转换图片和音频格式')
    parser.add_argument('-j', '--jobs', type=int, default=os.cpu_count(),
                        help='并发线程数 (默认: CPU核心数)')
    parser.add_argument('-d', '--directory', default='.',
                        help='目标目录 (默认: 当前目录)')
    args = parser.parse_args()

    # 检查FFmpeg是否可用
    try:
        subprocess.run(['ffmpeg', '-version'], 
                       check=True, 
                       stdout=subprocess.DEVNULL, 
                       stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.error("未找到FFmpeg! 请先安装FFmpeg并添加到系统PATH")
        return

    # 创建任务队列
    task_queue = queue.Queue()
    root_dir = os.path.abspath(args.directory)
    
    # 收集文件
    for file_path in find_files(root_dir):
        task_queue.put(file_path)
    
    if task_queue.empty():
        logger.info("没有发现需要转换的文件")
        return
    
    logger.info(f"发现 {task_queue.qsize()} 个文件待处理，使用 {args.jobs} 线程...")
    logger.warning("注意: 所有源文件将在处理后删除!")
    
    # 创建工作线程
    threads = []
    for _ in range(min(args.jobs, task_queue.qsize())):
        t = threading.Thread(target=worker, args=(task_queue,))
        t.start()
        threads.append(t)
    
    # 等待所有任务完成
    task_queue.join()
    
    # 停止工作线程
    for t in threads:
        t.join()
    
    logger.info("所有任务处理完成，源文件已删除")

if __name__ == "__main__":
    main()