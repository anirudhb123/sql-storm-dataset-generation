-- Performance Benchmarking SQL Query

-- Calculate the average score of questions, grouped by tags, within the last year
WITH TagScores AS (
    SELECT 
        t.TagName,
        AVG(p.Score) AS AverageScore,
        COUNT(p.Id) AS QuestionCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        t.TagName
)

-- Get users with their reputation and the number of badges, along with their total score from their posts
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount,
    COALESCE(SUM(p.Score), 0) AS TotalPostScore,
    AVG(ts.AverageScore) AS AvgTagScore
FROM 
    Users u
LEFT JOIN 
    Badges b ON b.UserId = u.Id
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    TagScores ts ON true -- Cross join with average scores for tags
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC, TotalPostScore DESC
LIMIT 100;

-- Retrieve the count of votes for questions within a specific date range
SELECT 
    p.Title,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.PostTypeId = 1 -- Only questions
    AND p.CreationDate BETWEEN '2023-01-01' AND '2023-10-01'
GROUP BY 
    p.Title
ORDER BY 
    VoteCount DESC
LIMIT 50;
