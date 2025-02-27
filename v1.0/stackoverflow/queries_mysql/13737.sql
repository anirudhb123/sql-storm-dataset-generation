
SELECT 
    P.Title AS QuestionTitle,
    P.CreationDate AS QuestionDate,
    P.ViewCount AS NumberOfViews,
    P.Score AS QuestionScore,
    A.CreationDate AS AnswerDate,
    TIMESTAMPDIFF(SECOND, P.CreationDate, A.CreationDate) AS ResponseTimeInSeconds,
    A.Score AS AnswerScore,
    U.DisplayName AS AnswererDisplayName
FROM 
    Posts P
JOIN 
    Posts A ON P.Id = A.ParentId
JOIN 
    Users U ON A.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
    AND A.PostTypeId = 2 
GROUP BY 
    P.Title, 
    P.CreationDate, 
    P.ViewCount, 
    P.Score, 
    A.CreationDate, 
    A.Score, 
    U.DisplayName
ORDER BY 
    ResponseTimeInSeconds;
