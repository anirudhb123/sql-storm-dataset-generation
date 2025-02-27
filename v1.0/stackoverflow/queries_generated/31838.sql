WITH RecursivePostHierarchy AS (
    -- CTE to traverse post hierarchy, specifically for answers and their parents
    SELECT 
        Id,
        ParentId,
        OwnerUserId,
        Title,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Starting with root questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
)

, UserActivity AS (
    -- Aggregating users with their question and answer counts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT q.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(a.Score) AS TotalAnswerScore
    FROM 
        Users u
    LEFT JOIN 
        Posts q ON q.OwnerUserId = u.Id AND q.PostTypeId = 1  -- Questions
    LEFT JOIN 
        Posts a ON a.OwnerUserId = u.Id AND a.PostTypeId = 2  -- Answers
    GROUP BY 
        u.Id, u.DisplayName
)

-- Main query selecting interesting metrics and combining results
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount,
    ua.AnswerCount,
    COALESCE(ua.TotalAnswerScore, 0) AS TotalAnswerScore,
    COUNT(DISTINCT r.Id) AS AnswerWithParentCount,
    AVG(r.Score) AS AvgAnswerScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    UserActivity ua
LEFT JOIN 
    RecursivePostHierarchy r ON ua.UserId = r.OwnerUserId AND r.Level = 1  -- Answers only
LEFT JOIN 
    PostLinks pl ON pl.PostId = r.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = pl.RelatedPostId
LEFT JOIN 
    Badges b ON b.UserId = ua.UserId
GROUP BY 
    ua.UserId, ua.DisplayName, ua.QuestionCount, ua.AnswerCount, ua.TotalAnswerScore
HAVING 
    ua.QuestionCount > 5  -- Filter out users with more than 5 questions
ORDER BY 
    TotalAnswerScore DESC, 
    AnswerCount DESC;
