
WITH QuestionData AS (
    SELECT 
        p.Id AS QuestionId,
        p.CreationDate,
        p.AcceptedAnswerId,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id) AS VoteCount,
        COALESCE(p.LastActivityDate, p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
ResponseTime AS (
    SELECT 
        q.QuestionId,
        DATEDIFF(SECOND, q.CreationDate, a.CreationDate) AS ResponseTimeInSeconds
    FROM 
        QuestionData q
    LEFT JOIN 
        Posts a ON q.AcceptedAnswerId = a.Id
)

SELECT 
    AVG(r.ResponseTimeInSeconds) AS AvgResponseTime,
    AVG(q.AnswerCount) AS AvgAnswersPerQuestion,
    AVG(q.VoteCount) AS AvgVotesPerQuestion
FROM 
    QuestionData q
JOIN 
    ResponseTime r ON q.QuestionId = r.QuestionId
GROUP BY 
    q.QuestionId, q.AnswerCount, q.VoteCount;
