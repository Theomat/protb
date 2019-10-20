public interface DataObject {
  public int size();
  public int write(byte[] array, int offset);
  public int read(byte[] array, int offset);
}
