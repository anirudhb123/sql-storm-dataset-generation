WITH RECURSIVE PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        pp.Id,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pp.CreationDate,
        Level + 1
    FROM 
        PopularPosts pp
    JOIN 
        Posts a ON a.ParentId = pp.Id
    WHERE 
        a.PostTypeId = 2 -- Only answers
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS NumberOfQuestions,
    SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore,
    SUM(CASE WHEN a.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(NULLIF(p.CreationDate, p.ClosedDate)) AS LastActiveDate,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
LEFT JOIN 
    Posts a ON p.Id = a.ParentId -- Answers to those questions
LEFT JOIN 
    Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '<>'))::int) -- Assuming tags are in <tag1><tag2>
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    TotalScore DESC, LastActiveDate DESC
LIMIT 10;

-- Performance benchmarking for posts versus badges
WITH BadgeUserCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

PostScoreAverage AS (
    SELECT 
        OwnerUserId,
        AVG(Score) AS AvgPostScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    GROUP BY 
        OwnerUserId
)

SELECT 
    u.DisplayName,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount,
    COALESCE(ps.AvgPostScore, 0) AS AvgPostScore
FROM 
    Users u
LEFT JOIN 
    BadgeUserCount bc ON u.Id = bc.UserId
LEFT JOIN 
    PostScoreAverage ps ON u.Id = ps.OwnerUserId
WHERE 
    u.Reputation >= 1000
ORDER BY 
    BadgeCount DESC, AvgPostScore DESC
LIMIT 10;

-- Cross post analysis between correlated questions and answers
SELECT 
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    a.Id AS AnswerId,
    a.Body AS AnswerBody,
    a.Score AS AnswerScore,
    Q.Tags AS QuestionTags
FROM 
    Posts q
LEFT JOIN 
    Posts a ON a.ParentId = q.Id
WHERE 
    q.PostTypeId = 1 -- Questions
AND 
    q.CreationDate > NOW() - INTERVAL '30 days' -- Questions from the last 30 days
AND 
    (a.Score > 0 OR a.Id IS NULL) -- Only include positive scoring answers or no answers
ORDER BY 
    q.Score DESC, a.Score DESC;
