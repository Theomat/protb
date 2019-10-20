public final class DataReader {
  private DataReader(){}

  public static final byte readByte(byte[] array, int offset){
    return array[offset];
  }
  public static final short readShort(byte[] array, int offset){
    return ((short) array[offset] << 8) + array[offset + 1];
  }
  public static final int readInt(byte[] array, int offset){
    return ((((((int) array[offset] << 8) + array[offset + 1]) << 8) + array[offset + 2]) << 8) + array[offset + 3];
  }
  public static final long readLong(byte[] array, int offset){
    long high = readInt(array, offset);
    int low = readInt(array, offset + 4);
    return high << 32 + low;
  }
  public static final String readCString(byte[] array, int offset){
    StringBuffer buffer = new StringBuffer();
    while(array[offset] != 0){
      buffer.append(array[offset]);
      offset += 1;
    }
    return buffer.toString();
  }

  public static final String readString(byte[] array, int offset, int length){
    StringBuffer buffer = new StringBuffer();
    for(int i = 0; i < length; i++){
      buffer.append(array[offset]);
      offset += 1;
    }
    return buffer.toString();
  }
}
