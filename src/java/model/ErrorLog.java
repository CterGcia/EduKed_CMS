package model;

import java.sql.Timestamp;

public class ErrorLog {
    private long errorId;
    private String errorCode;
    private String message;
    private String stack;
    private Timestamp timestamp;

    public long getErrorId() {
        return errorId;
    }

    public void setErrorId(long errorId) {
        this.errorId = errorId;
    }

    public String getErrorCode() {
        return errorCode;
    }

    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getStack() {
        return stack;
    }

    public void setStack(String stack) {
        this.stack = stack;
    }

    public Timestamp getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Timestamp timestamp) {
        this.timestamp = timestamp;
    }
}
