WITH RecursivePostHierarchy AS (
    -- CTE to recursively get the hierarchy of posts (questions and answers)
    SELECT 
        Id,
        ParentId,
        OwnerUserId,
        CreationDate,
        Title,
        0 AS Level
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
FilteredPosts AS (
    -- CTE to filter and prepare posts with at least one answer and their answer count
    SELECT 
        r.Id AS QuestionId,
        r.Title AS QuestionTitle,
        COALESCE(a.AnswerCount, 0) AS TotalAnswers,
        r.OwnerUserId,
        r.CreationDate
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2  -- Considering only answers
        GROUP BY 
            ParentId
    ) a ON r.Id = a.ParentId
    WHERE 
        r.Level = 0  -- Only questions
),
UserAnalytics AS (
    -- CTE to get users and their respective badge counts and average reputation
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalOutput AS (
    -- Final output combining filtered posts and user analytics
    SELECT 
        p.QuestionId,
        p.QuestionTitle,
        p.TotalAnswers,
        u.DisplayName AS Author,
        u.BadgeCount,
        u.AvgReputation,
        CASE 
            WHEN p.TotalAnswers > 0 THEN 'Has Answers'
            ELSE 'No Answers'
        END AS AnswerStatus
    FROM 
        FilteredPosts p
    JOIN 
        UserAnalytics u ON p.OwnerUserId = u.UserId
    ORDER BY 
        p.TotalAnswers DESC, 
        u.AvgReputation DESC
)
-- Final selection and output of the data
SELECT 
    QuestionId, 
    QuestionTitle, 
    TotalAnswers, 
    Author, 
    BadgeCount, 
    AvgReputation, 
    AnswerStatus
FROM 
    FinalOutput
WHERE 
    BadgeCount > 1  -- Only users with more than 1 badge
    AND AvgReputation > 50  -- Users with higher average reputation
ORDER BY 
    TotalAnswers DESC, 
    AvgReputation DESC;
