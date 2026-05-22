package servlets;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.Random;
import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/CaptchaServlet")
public class CaptchaServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        response.setContentType("image/png");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        
        int width = 150;
        int height = 44;
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = image.createGraphics();
        
        // Draw background (Neo-Brutalist surface style)
        g2d.setColor(Color.decode("#121824")); 
        g2d.fillRect(0, 0, width, height);
        
        // Generate random string
        String chars = "ABCDEFGHJKLMNOPQRSTUVWXYZ23456789"; // Removed ambiguous characters
        StringBuilder captchaString = new StringBuilder();
        Random rand = new Random();
        for (int i = 0; i < 5; i++) {
            captchaString.append(chars.charAt(rand.nextInt(chars.length())));
        }
        
        // Store in session
        request.getSession().setAttribute("captcha_key", captchaString.toString());
        
        // Draw characters with styling
        g2d.setFont(new Font("Monospaced", Font.BOLD, 22));
        for (int i = 0; i < captchaString.length(); i++) {
            g2d.setColor(i % 2 == 0 ? Color.decode("#00F2FE") : Color.WHITE);
            int x = 20 + (i * 24);
            int y = 28 + (rand.nextInt(8) - 4);
            g2d.drawString(String.valueOf(captchaString.charAt(i)), x, y);
        }
        
        // Draw noise lines
        g2d.setColor(Color.decode("#263147"));
        for (int i = 0; i < 6; i++) {
            g2d.drawLine(rand.nextInt(width), rand.nextInt(height), rand.nextInt(width), rand.nextInt(height));
        }
        
        g2d.dispose();
        ImageIO.write(image, "png", response.getOutputStream());
    }
}
