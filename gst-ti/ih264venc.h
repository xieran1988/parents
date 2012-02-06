/* ======================================================================== */
/*   Copyright (c) 2005 Texas Instruments Inc.  All rights reserved.        */
/*   Exclusive property of the Video & Imaging Products, Emerging End       */
/*   Equipment group of Texas Instruments India Limited. Any handling,      */
/*   use, disclosure, reproduction, duplication, transmission, or storage   */
/*   of any part of this work by any means is subject to restrictions and   */
/*   prior written permission set forth in TI's program license agreements  */
/*   and associated software documentation.                                 */
/*                                                                          */
/*   This copyright notice, restricted rights legend, or other proprietary  */
/*   markings must be reproduced without modification in any authorized     */
/*   copies of any part of this work.  Removal or modification of any part  */
/*   of this notice is prohibited.                                          */
/* ------------------------------------------------------------------------ */
/*            Copyright (c) 2005 Texas Instruments, Incorporated.           */
/*                           All Rights Reserved.                           */
/* ======================================================================== */


/*!
  @file     ih264venc.h
  @brief    IH264VENC Interface Header
  @author   Pramod Kumar Swami
  @version  0.1 - Nov 05,2004
  @version  0.2 - Nov 18,2005 XMI changes inclusion
  @version  0.3 - May 20,2006 Added more parameters to control the encoder
                  through Dynamic parameter 
*/

/**
 *  @defgroup   DSPH264 IH264VENC_TI (C64P)
 *
 *              The IH264VENC_TI interface enables encoding in H264 format
 *
 */

#ifndef IH264VENC_  //--{

#define IH264VENC_



/** @ingroup    DSPH264 */
/*@{*/


#ifdef __cplusplus
extern "C" {
#endif

//!< Directives to control Buffer sizes
#define MAXNUMSLCGPS      8  //!< max. number of slice groups

//!< control method commands
#define IH264VENC_GETSTATUS      XDM_GETSTATUS
#define IH264VENC_SETPARAMS      XDM_SETPARAMS
#define IH264VENC_RESET          XDM_RESET
#define IH264VENC_FLUSH          XDM_FLUSH
#define IH264VENC_SETDEFAULT     XDM_SETDEFAULT
#define IH264VENC_GETBUFINFO     XDM_GETBUFINFO
#define IH264VENC_GETVERSION     XDM_GETVERSION  //XDM1.0


//!< H264 Encoder Specific Error Code bits
typedef enum 
{
  IH264VENC_SEQPARAMERR=0,          //!< Indicates error during sequence parameter set generation
  IH264VENC_PICPARAMERR,            //!< Indicates error during picture parameter set generation
  IH264VENC_COMPRESSEDSIZEOVERFLOW, //!< Compressed data exceeds the maximum compressed size limit
  IH264VENC_INVALIDQPPARAMETER,     //!< Out of Range initial Quantization parameter
  IH264VENC_INVALIDPROFILELEVEL,    //!< Invalid profile or Level
  IH264VENC_INVALIDRCALGO,          //!< Invalid RateControl Algorithm
  IH264VENC_INVALIDSEARCHRANGE,          //!< Invalid RateControl Algorithm
  IH264VENC_SLICEEXCEEDSMAXBYTES,   //!< Slice exceeds the maximum allowed bytes
  IH264VENC_DEVICENOTREADY,          //!< Indicates the device is not ready
  IH264VENC_ERROR_NULLPOINTER,		  //!< Indicates the invalid pointers have been passed to the algorithm	//debjani_CDMR7690_api
  IH264VENC_ERROR_INVALIDSTRUCTSIZE //!< Indicates the invalid structure size has been passed to the algorithm		


} IH264VENC_ErrorBit;

//!< H.264 Encoder Slice and Picture level Loop Filter Control
typedef enum 
{
  FILTER_ALL_EDGES = 0,             //!< Enable filtering of all the edges
  DISABLE_FILTER_ALL_EDGES,         //!< Disable filtering of all the edges
  DISABLE_FILTER_SLICE_EDGES        //!< Disable filtering of slice edges 

} IH264VENC_LoopFilterParams ;


//!< H.264 Encoder Slice level Control for Intra4x4 Modes 
typedef enum 
{
  INTRA4x4_NONE = 0 ,   //!< Disable Intra4x4 modes 
  INTRA4x4_ISLICES  ,   //!< Enable Intra4x4 modes only in I Slices
  INTRA4x4_IPSLICES     //!< Enable Intra4x4 modes only in I and P Slices

} IH264VENC_Intra4x4Params ;

//!< Level Identifier for H.264 Encoder
typedef enum
{
  IH264_LEVEL_10 = 10,  //!< Level 1.0
  IH264_LEVEL_1b =  9,  //!< Level 1.b
  IH264_LEVEL_11 = 11,  //!< Level 1.1
  IH264_LEVEL_12 = 12,  //!< Level 1.2
  IH264_LEVEL_13 = 13,  //!< Level 1.3
  IH264_LEVEL_20 = 20,  //!< Level 2.0
  IH264_LEVEL_21 = 21,  //!< Level 2.1
  IH264_LEVEL_22 = 22,  //!< Level 2.2
  IH264_LEVEL_30 = 30   //!< Level 3.0

} IH264VENC_Level ;


//!< Picture Order Count Type Identifier for H.264 Encoder
typedef enum
{
  IH264_POC_TYPE_0 = 0,  //!< POC type 0
  IH264_POC_TYPE_2 = 2   //!< POC type 2

} IH264VENC_PicOrderCountType ;

//!< Picture Order Count Type Identifier for H.264 Encoder
typedef enum
{
  IH264_INTRAREFRESH_NONE       = 0 ,  //!< Doesn't insert forcefully intra macro blocks
  IH264_INTRAREFRESH_CYCLIC_MBS     ,  //!< Insters intra macro blocks in a cyclic fashion :
                                       //!< cyclic interval is equal to airMbPeriod
  IH264_INTRAREFRESH_CYCLIC_SLICES  ,  //!< Insters Intra Slices in a cyclic fashion: 
                                       //!< no of intra slices is equal to sliceRefreshRowNumber
  IH264_INTRAREFRESH_RDOPT_MBS         //!< position of intra macro blocks is intelligently 
                                       //!< chosen by encoder, but the number of forcely coded 
                                       //!< intra macro blocks in a frame is gaurnteed to be 
                                       //!< equal to totalMbsInFrame/airMbPeriod : Not valid for DM6446

} IH264VENC_IntraRefreshMethods ;

typedef enum
{
  IH264_INTERLEAVED_SLICE_GRP             = 0 , //!< 0 : Interleaved Slices
  IH264_FOREGRND_WITH_LEFTOVER_SLICE_GRP  = 2 , //!< 2 : ForeGround with Left Over
  IH264_RASTER_SCAN_SLICE_GRP             = 4   //!< 4 : Raster Scan

} IH264VENC_SliceGroupMapType ;

typedef enum
{
  IH264_RASTER_SCAN             = 0 , //!< 0 : Raster scan order
  IH264_REVERSE_RASTER_SCAN           //!< 1 : Reverse Raster Scan Order

} IH264VENC_SliceGroupChangeDirection ;


//--------------------------------------------------------------------------
//!< Status structure defines the parameters that can be changed or read
//during real-time operation of the alogrithm

typedef struct
{
  IVIDENC1_Status        videncStatus ;  //!< Status of the h264 encoder along with
                                        //!< error information, if any
  XDAS_Int32       mvDataSize   ; //!< Size of the mvData provided back (only useful when IH264VENC_DynamicParams->mvDataEnable is set)

} IH264VENC_Status;

//!< Type of the stream to be generated with Call-back
typedef enum
{
  IH264_BYTE_STREAM = 0,
  IH264_NALU_STREAM

}IH264VENC_StreamFormat;


typedef IVIDENC1_Cmd IH264VENC_Cmd;

//--------------------------------------------------------------------------
//!< This structure defines the creation parameters for all H264VENC objects
typedef struct
{
  IVIDENC1_Params  videncParams;   //!< Initilization parameters common to all video encoders
  XDAS_Int32      profileIdc;     //!< profile idc
  IH264VENC_Level levelIdc;       //!< level idc
  XDAS_Int32      rcAlgo;         //!< Algorithm to be used by Rate Control Scheme Range[0,1]
  XDAS_Int32      searchRange;    //!< search range - integer pel search and 16x16 blocks.  The search window is
                                  //!< generally around the predicted vector. Max vector is 2xmcrange.  For 8x8
                                  //!< and 4x4 block sizes the search range is 1/2 of that for 16x16 blocks
} IH264VENC_Params;


//--------------------------------------------------------------------------
//!< This structure must be the first field of all H264VENC instance objects
typedef struct IH264VENC_Obj
{
    struct IH264VENC_Fxns *fxns;
} IH264VENC_Obj;

//--------------------------------------------------------------------------
//!< This handle is used to reference all H264VENC instance objects
typedef struct IH264VENC_Obj *IH264VENC_Handle;

//--------------------------------------------------------------------------
//!<Default parameter values for H264VENC instance objects
extern IH264VENC_Params IH264VENC_PARAMS;

//--------------------------------------------------------------------------
//!< This structure defines the run time parameters for all H264VENC objects
typedef struct IH264VENC_DynamicParams {
  IVIDENC1_DynamicParams videncDynamicParams ; //!< must be followed for all video encoders
  XDAS_Int32      qpIntra                   ; //!< initial QP of I frames Range[-1,51]. -1 is for auto initialization.
  XDAS_Int32      qpInter                   ; //!< initial QP of P frames Range[-1,51]. -1 is for auto initialization.
  XDAS_Int32      qpMax                     ; //!< Maximum QP to be used  Range[0,51]
  XDAS_Int32      qpMin                     ; //!< Minimum QP to be used  Range[0,51]
  XDAS_Int32      lfDisableIdc              ; //!< Controls enable/disable loop filter, See IH264VENC_LoopFilterParams for more details
  XDAS_Int32      quartPelDisable           ; //!< enable/disable Quarter Pel Interpolation
  XDAS_Int32      airMbPeriod               ; //!< Adaptive Intra Refesh MB Period: Period at which intra macro blocks should be insterted in a frame
  XDAS_Int32      maxMBsPerSlice            ; //!< Maximum number of macro block in a slice <minimum value is 8>
  XDAS_Int32      maxBytesPerSlice          ; //!< Maximum number of bytes in a slice 
  XDAS_Int32      sliceRefreshRowStartNumber; //!< Row number from which slice needs to be intra coded
  XDAS_Int32      sliceRefreshRowNumber     ; //!< Number of rows to be coded as intra slice
  XDAS_Int32      filterOffsetA             ; //!< alpha offset for loop filter [-12, 12] even number
  XDAS_Int32      filterOffsetB             ; //!< beta offset for loop filter [-12, 12] even number
  XDAS_Int32      log2MaxFNumMinus4         ; //!< Limits the maximum frame number in the bit-stream to (1<< (log2MaxFNumMinus4 + 4)) Range[0,12]
  XDAS_Int32      chromaQPIndexOffset       ; //!< Specifies offset to be added to luma QP for addressing QPC values table for chroma components. Valid value is between -12 and 12, (inclusive)
  XDAS_Int32      constrainedIntraPredEnable; //!< Controls the intra macroblock coding in P slices [0,1]
  XDAS_Int32      picOrderCountType         ; //!< Picture Order count type Valid values 0, 2
  XDAS_Int32      maxMVperMB                ; //!< enable/Disable Multiple Motion vector per MB, valid values are [1, 4] [For DM6446, allowed value is only 1]
  XDAS_Int32      intra4x4EnableIdc         ; //!< See IH264VENC_Intra4x4Params for more details
  XDAS_Int32      mvDataEnable              ; //!< enable/Disable Motion vector access
  XDAS_Int32      hierCodingEnable          ; //!< Enable/Disable Hierarchical P Frame (non-reference P frame) Coding. [Not useful for DM6446]
  XDAS_Int32      streamFormat              ; //!< Signals the type of stream generated with Call-back
  XDAS_Int32      intraRefreshMethod        ; //!< Mechanism to do intra Refresh, see IH264VENC_IntraRefreshMethods for valid values
  XDAS_Int32      perceptualQuant           ; //!< Enable Perceptual Quantization a.k.a. Perceptual Rate Control
  XDAS_Int32      sceneChangeDet            ; //!< Enable Scene Change Detection
//  XDAS_Int32      enableFrameSkip           ; //!< frameSkip control for VBR RC. (For CBR frame skip is always on) [0, 1]. 

  void   (*pfNalUnitCallBack)(
      XDAS_Int32    *pNalu, 
      XDAS_Int32    *pPacketSizeInBytes,
      void *pContext 
      )    ; //!< Function pointer of the call-back function to be used by Encoder

  void *pContext                            ; //!< pointer to context structure used during callback

  //!< Following Parameter are related to Arbitrary Slice Ordering (ASO)
  XDAS_Int32 numSliceASO                    ; //!< Number of valid enteries in asoSliceOrder array valid range is [0,8], 
                                              //!< where 0 and 1 doesn't have any effect
  XDAS_Int32 asoSliceOrder[MAXNUMSLCGPS]    ; //!< Array containing the order of slices in which they should
                                              //!< be present in bit-stream. vaild enteries are [0, any entry lesser than numSlicesASO]

  //!< Following Parameter are related to Flexible macro block ordering (FMO)
  XDAS_Int32 numSliceGroups                 ; //!< Total Number of slice groups, valid enteries are [0,8]
  XDAS_Int32 sliceGroupMapType              ; //!< Slice GroupMapType : For Valid enteries see IH264VENC_SliceGroupMapType
  XDAS_Int32 sliceGroupChangeDirectionFlag  ; //!< Slice Group Change Direction Flag: Only valid when sliceGroupMapType 
                                              //!< is equal to IH264_RASTER_SCAN_SLICE_GRP. 
                                              //!< For valid values refer IH264VENC_SliceGroupChangeDirection
  XDAS_Int32 sliceGroupChangeRate           ; //!< Slice Group Change Rate: Only valid when sliceGroupMapType 
                                              //!< is equal to IH264_RASTER_SCAN_SLICE_GRP. 
                                              //!< valid values are : [0, factor of number of Mbs in a row]
  XDAS_Int32 sliceGroupChangeCycle          ; //!< Slice Group Change Cycle: Only valid when sliceGroupMapType 
                                              //!< is equal to IH264_RASTER_SCAN_SLICE_GRP. 
                                              //!< Valid values can be 0 to numMbsRowsInPicture, also constrained
                                              //!< by sliceGroupChangeRate*sliceGroupChangeCycle < totalMbsInFrame
  XDAS_Int32 sliceGroupParams[MAXNUMSLCGPS] ; //!< This field is useful in case of sliceGroupMapType equal to either 
                                              //!< IH264_INTERLEAVED_SLICE_GRP or IH264_FOREGRND_WITH_LEFTOVER_SLICE_GRP
                                              //!< In both cases it has different meaning:
                                              //!< In case of IH264_INTERLEAVED_SLICE_GRP:
                                              //!< The i-th entery in this array is used to specify the number of consecutive 
                                              //!< slice group macroblocks to be assigned to the i-th slice group in 
                                              //!< raster scan order of slice group macroblock units.
                                              //!< Valid values are 0 to totalMbsInFrame again constrained by sum of all the elements
                                              //!< shouldn't exceed totalMbsInFrame
                                              //!< In case of IH264_FOREGRND_WITH_LEFTOVER_SLICE_GRP:
                                              //!< First entry in the array specify the start position of foreground region in terms 
                                              //!< of macroblock number, valid values are [0, totalMbsInFrame-1]
                                              //!< Second entry in the array specify the end position of foreground region in terms 
                                              //!< of macroblock number, valid values are [0, totalMbsInFrame-1] with following constrains:
                                              //!< endPos > startPos && endPos%mbsInOneRow > startPos%mbsInOneRow
} IH264VENC_DynamicParams;

extern IH264VENC_DynamicParams H264VENC_TI_DYNAMICPARAMS;

//--------------------------------------------------------------------------
//!< This structure provides the Input parameters for H.264 Encode call
typedef struct IH264VENC_InArgs {

  IVIDENC1_InArgs  videncInArgs; //!< Parameters common to video encoders
} IH264VENC_InArgs;

//--------------------------------------------------------------------------
//!< This structure provides the Output parameters for H.264 Encode call
typedef struct IH264VENC_OutArgs {

  IVIDENC1_OutArgs  videncOutArgs;
//  XDAS_Int32       mvDataSize   ; //!< Size of the mvData provided back (only useful when IH264VENC_DynamicParams->mvDataEnable is set)

} IH264VENC_OutArgs;

//--------------------------------------------------------------------------
//!< This structure defines all of the operations on H264VENC objects
typedef struct IH264VENC_Fxns
{
    IVIDENC1_Fxns ividenc;

} IH264VENC_Fxns;

//debjani_fps
typedef enum
{
  XDM_USER_DEFINED_HIGH_SPEED = 4
}EX_XDM_EncodingPreset;
#ifdef __cplusplus
}
#endif

/*@}*/ /* ingroup DSPH264 */

#endif  //IH264VENC_ //--}

/* ======================================================================== */
/* End of file : ih264venc.h                                               */
/* ------------------------------------------------------------------------ */
/*            Copyright (c) 2005 Texas Instruments, Incorporated.           */
/*                           All Rights Reserved.                           */
/* ======================================================================== */

