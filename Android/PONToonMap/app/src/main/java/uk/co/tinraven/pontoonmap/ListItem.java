package uk.co.tinraven.pontoonmap;

public class ListItem {
    String name;
    boolean enabled;

    public ListItem(String name,boolean enabled)
    {
        this.name=name;
        this.enabled=enabled;
    }
    public String getName()
    {
        return name;
    }
    public boolean getEnabled()
    {
        return enabled;
    }
}
