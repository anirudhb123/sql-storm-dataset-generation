WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all answers related to questions
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2  -- Answers
),

PostStatistics AS (
    -- CTE to calculate statistics for posts and their answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        MAX(a.Score) AS HighestAnswerScore,
        MIN(a.CreationDate) AS FirstAnswerDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId  -- Join to answers
    WHERE 
        p.PostTypeId = 1  -- Only consider questions
    GROUP BY 
        p.Id
),

UserActivity AS (
    -- CTE to gather user activity related to the posts they have created
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

PostHistoryActivity AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24)  -- Title, Body, Tags edits, Suggested Edits
    GROUP BY 
        ph.PostId
)

-- Final query to aggregate results
SELECT 
    ps.PostId,
    ps.Title,
    ps.AnswerCount,
    ps.HighestAnswerScore,
    u.DisplayName AS PostOwner,
    u.TotalPosts AS OwnerTotalPosts,
    u.TotalAnswers AS OwnerTotalAnswers,
    u.TotalBadges AS OwnerTotalBadges,
    COALESCE(SUM(pha.EditCount), 0) AS TotalEdits,
    COALESCE(MAX(pha.LastEditDate), 'No Edits') AS LastEdit,
    CASE 
        WHEN ps.FirstAnswerDate IS NOT NULL THEN DATEDIFF(CURRENT_TIMESTAMP, ps.FirstAnswerDate) 
        ELSE NULL 
    END AS DaysUntilFirstAnswer
FROM 
    PostStatistics ps
JOIN 
    UserActivity u ON ps.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistoryActivity pha ON ps.PostId = pha.PostId
GROUP BY 
    ps.PostId, ps.Title, u.DisplayName, u.TotalPosts, u.TotalAnswers, u.TotalBadges
ORDER BY 
    ps.AnswerCount DESC, ps.HighestAnswerScore DESC;
