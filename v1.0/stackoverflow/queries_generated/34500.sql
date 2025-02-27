WITH RecursivePostHierarchy AS (
    -- Base case: Select all top-level questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    -- Recursive case: Join answers to their questions
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.ViewCount,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy q ON a.ParentId = q.PostId
    WHERE 
        a.PostTypeId = 2  -- Answers
),
PostStats AS (
    -- Aggregate stats for questions and include statistics for answers
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.CreationDate,
        r.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        Posts a ON r.PostId = a.ParentId AND a.PostTypeId = 2
    GROUP BY 
        r.PostId, r.Title, r.OwnerUserId, r.CreationDate, r.ViewCount
),
UserActivity AS (
    -- Collect user activity statistics
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    u.DisplayName AS Owner,
    ps.CreationDate,
    ps.ViewCount,
    ps.AnswerCount,
    ps.TotalAnswerScore,
    ua.QuestionCount AS UserQuestions,
    ua.AnswerCount AS UserAnswers,
    ua.TotalAnswerScore AS UserTotalAnswerScore,
    CASE 
        WHEN ps.AnswerCount > 0 THEN ROUND((ps.TotalAnswerScore * 1.0) / NULLIF(ps.AnswerCount, 0), 2)
        ELSE NULL
    END AS AvgAnswerScore
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
WHERE 
    ps.ViewCount > 50  -- Filter questions with more than 50 views
ORDER BY 
    ps.ViewCount DESC,
    ps.TotalAnswerScore DESC;
