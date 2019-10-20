public final class DataWriter {
  private DataWriter(){}

  public static final int writeByte(byte[] array, int offset, byte value, boolean consume){
    if(consume){
      array[offset] = value;
      return offset + 1;
    } else {
      array[offset] |= value;
      return offset;
    }
  }
  public static final int writeShort(byte[] array, int offset, short value, boolean consume){
    if(consume){
      array[offset] = (value >> 8) & 255;
      array[offset + 1] = value & 255;
      return offset + 2;
    } else {
      array[offset] |= (value >> 8) & 255;
      array[offset + 1] |= value & 255;
      return offset;
    }
  }
  public static final int writeInt(byte[] array, int offset, int value){
    if(consume){
      array[offset] = (value >> 24) & 255;
      array[offset + 1] = (value >> 16) & 255;
      array[offset + 2] = (value >> 8) & 255;
      array[offset + 3] = value & 255;
      return offset + 4;
    } else {
      array[offset] |= (value >> 24) & 255;
      array[offset + 1] |= (value >> 16) & 255;
      array[offset + 2] |= (value >> 8) & 255;
      array[offset + 3] |= value & 255;
      return offset;
    }
  }
  public static final int writeLong(byte[] array, int offset, long value, boolean consume){
    if(consume){
      array[offset] = (value >> 56) & 255;
      array[offset + 1] = (value >> 48) & 255;
      array[offset + 2] = (value >> 40) & 255;
      array[offset + 3] = (value >> 32) & 255;
      array[offset + 4] = (value >> 24) & 255;
      array[offset + 5] = (value >> 16) & 255;
      array[offset + 6] = (value >> 8) & 255;
      array[offset + 7] = value & 255;
      return offset + 8;
    } else {
      array[offset] |= (value >> 56) & 255;
      array[offset + 1] |= (value >> 48) & 255;
      array[offset + 2] |= (value >> 40) & 255;
      array[offset + 3] |= (value >> 32) & 255;
      array[offset + 4] |= (value >> 24) & 255;
      array[offset + 5] |= (value >> 16) & 255;
      array[offset + 6] |= (value >> 8) & 255;
      array[offset + 7] |= value & 255;
      return offset;
    }
  }
  public static final void writeCString(byte[] array, int offset, String value){
    for(int i = 0; i < value.length(); i++){
      array[offset++] = value[i];
    }
    array[offset] = 0;
  }
  public static final void writeString(byte[] array, int offset, String value, int length, char fill){
    int maximum = Math.min(length, value.length());
    for(int i = 0; i < maximum; i++){
      array[offset++] = value[i];
    }
    for(int i = maximum; i < length; i++){
      array[offset++] = fill;
    }
  }
}
