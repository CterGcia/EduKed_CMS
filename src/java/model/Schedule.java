package model;

import java.sql.Time;

public class Schedule {
    private int scheduleId;
    private int dayOfWeek;
    private Time startTime;
    private Time endTime;
    private String room;

    public int getScheduleId() {
        return scheduleId;
    }

    public void setScheduleId(int scheduleId) {
        this.scheduleId = scheduleId;
    }

    public int getDayOfWeek() {
        return dayOfWeek;
    }

    public void setDayOfWeek(int dayOfWeek) {
        this.dayOfWeek = dayOfWeek;
    }

    public Time getStartTime() {
        return startTime;
    }

    public void setStartTime(Time startTime) {
        this.startTime = startTime;
    }

    public Time getEndTime() {
        return endTime;
    }

    public void setEndTime(Time endTime) {
        this.endTime = endTime;
    }

    public String getRoom() {
        return room;
    }

    public void setRoom(String room) {
        this.room = room;
    }

    public String getDisplayString() {
        String day;
        switch (dayOfWeek) {
            case 1: day = "Mon"; break;
            case 2: day = "Tue"; break;
            case 3: day = "Wed"; break;
            case 4: day = "Thu"; break;
            case 5: day = "Fri"; break;
            case 6: day = "Sat"; break;
            case 7: day = "Sun"; break;
            default: day = "?";
        }
        return day + " " + startTime.toString().substring(0, 5) + "-" + endTime.toString().substring(0, 5) + " (" + room + ")";
    }
}
