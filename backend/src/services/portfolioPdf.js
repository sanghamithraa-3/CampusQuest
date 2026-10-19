import PDFDocument from "pdfkit";

function formatDate(date) {
  return new Intl.DateTimeFormat("en-IN", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Asia/Kolkata",
  }).format(date);
}

function printableUrl(url) {
  return url.match(/.{1,76}/g)?.join("\n") ?? url;
}

export function streamPortfolioPdf(portfolio, response) {
  const document = new PDFDocument({
    size: "A4",
    margins: { top: 48, bottom: 48, left: 52, right: 52 },
    info: {
      Title: `${portfolio.student.fullName} - Campus Quest Portfolio`,
      Author: "Campus Quest",
      Subject: "Student achievement portfolio",
    },
  });

  document.on("error", (error) => response.destroy(error));
  document.pipe(response);

  document
    .font("Helvetica-Bold")
    .fontSize(20)
    .fillColor("#17365D")
    .text("THIAGARAJAR COLLEGE OF ENGINEERING", { align: "center" });
  document
    .font("Helvetica")
    .fontSize(11)
    .fillColor("#46566B")
    .text("CAMPUS QUEST | STUDENT ACHIEVEMENT PORTFOLIO", {
      align: "center",
      characterSpacing: 0.7,
    });
  document.moveDown(1.5);
  document
    .moveTo(52, document.y)
    .lineTo(543, document.y)
    .strokeColor("#1C6E8C")
    .lineWidth(1.5)
    .stroke();
  document.moveDown();

  document.font("Helvetica-Bold").fontSize(15).fillColor("#17365D");
  document.text(portfolio.student.fullName);
  document.font("Helvetica").fontSize(10).fillColor("#222222");
  document.text(`Roll number: ${portfolio.student.rollNumber}`);
  document.text(`Department: ${portfolio.student.department}`);
  document.text(`Year of study: ${portfolio.student.yearOfStudy}`);
  document.text(`Generated: ${formatDate(new Date())}`);
  document.moveDown();

  document.font("Helvetica-Bold").fontSize(14).fillColor("#17365D");
  document.text("Achievements");
  document.moveDown(0.5);

  if (portfolio.achievements.length === 0) {
    document.font("Helvetica").fontSize(11).fillColor("#222222");
    document.text("No achievements have been submitted yet.");
  }

  portfolio.achievements.forEach((achievement, index) => {
    if (document.y > 690) {
      document.addPage();
    }
    document
      .font("Helvetica-Bold")
      .fontSize(12)
      .fillColor("#1C6E8C")
      .text(`${index + 1}. ${achievement.title}`);
    document.font("Helvetica").fontSize(10).fillColor("#222222");
    document.text(`Category: ${achievement.category}`);
    document.text(`Date: ${formatDate(achievement.date)}`);
    if (achievement.description) {
      document.text(`Description: ${achievement.description}`, {
        paragraphGap: 3,
      });
    }
    if (achievement.certificateUrl) {
      document.text(`Certificate: ${printableUrl(achievement.certificateUrl)}`, {
        link: achievement.certificateUrl,
        underline: true,
        color: "#1C6E8C",
        paragraphGap: 3,
      });
    }
    document.moveDown(0.75);
  });

  document.end();
}
