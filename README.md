# MATLAB
It's a simple project made in college. Develop an Image Processing Software Using MATLAB, Use MATLAB to implement an image processing software that mimics the functionality of Photoshop, GIMP, Meitu, or similar applications. The software should include the following features: Histogram Equalization、Image Saving、Image Scaling 、Image Enhancement、Color Transformation、Filter Processing、Image Segmentation、Image Recognition.

1、架构概览
  采用分层模块化架构，分为4个主要层次。
  ​  用户界面层：处理所有交互逻辑
  ​  业务逻辑层：核心图像处理算法
  ​  数据访问层：图像I/O操作
  ​  基础设施层：底层计算支持
  
  <img width="415" alt="image" src="https://github.com/user-attachments/assets/4772ffc2-d55d-4969-92bc-4ede21612fdb" />

2、详细架构设计
  （1）用户界面层 (UI Layer)
  核心组件：
  ImageProcessorMain.m：主程序入口
  createUIComponents.m：UI布局管理器
  processImage.m：处理流程控制器
  特性：
  双视图设计（原图/处理结果）
  功能按钮分组布局（基础/高级操作）
  采用MATLAB App Designer组件体系
  
  <img width="415" alt="image" src="https://github.com/user-attachments/assets/d976798c-7c69-4564-ab75-7b8ab573908b" />

  （2）功能逻辑层
  主要采用插件式模块设计，主要模块有：

  ![image](https://github.com/user-attachments/assets/c75c0aa3-9a5b-417a-8f28-d4498ad03a61)

  
  （3）数据访问层
  fileOperations.m 统一文件管理器：
  支持多格式I/O（jpg/png/bmp/tif）
  可以自动类型转换（double↔uint8）
  有异常安全处理机制
  
  <img width="415" alt="image" src="https://github.com/user-attachments/assets/b5d0acb0-16dd-4e5f-956f-fa5c883d1022" />

