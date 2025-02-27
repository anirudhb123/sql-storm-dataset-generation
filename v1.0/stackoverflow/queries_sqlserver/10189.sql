
SELECT 
    COUNT(DISTINCT CASE WHEN PostTypeId = 1 THEN OwnerUserId END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN PostTypeId = 2 THEN OwnerUserId END) AS TotalAnswers
FROM Posts;
