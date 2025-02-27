WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get the hierarchy of posts and their accepted answers
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM Posts 
    WHERE PostTypeId = 1 -- Starting from questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),

PostScoreDetails AS (
    -- Calculate total scores and average view counts for each question
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        SUM(COALESCE(a.Score, 0)) AS TotalAnswerScore,
        COUNT(a.Id) AS AnswerCount,
        AVG(p.ViewCount) AS AverageViewCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId -- Left join to get answers for each question
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title
),

TagsWithCounts AS (
    -- Get tags with their usage counts
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM Tags t
    LEFT JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%' -- Use LIKE to match tags
    GROUP BY t.TagName
),

UserBadges AS (
    -- Aggregate users by their badges count
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges, -- Gold badges
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges, -- Silver badges
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges -- Bronze badges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),

FinalResults AS (
    SELECT 
        q.Id AS QuestionId,
        q.Title,
        ps.TotalAnswerScore,
        ps.AverageViewCount,
        tc.TagName,
        ub.DisplayName AS UserWithMostBadges,
        ub.BadgeCount
    FROM PostScoreDetails ps
    JOIN RecursivePostHierarchy q ON ps.QuestionId = q.Id
    LEFT JOIN TagsWithCounts tc ON tc.PostCount > 0
    LEFT JOIN (
        SELECT 
            UserId,
            DisplayName,
            ROW_NUMBER() OVER (ORDER BY BadgeCount DESC) AS rn -- Use window function for ranking
        FROM UserBadges
    ) ub ON ub.rn = 1
)

-- Final selection
SELECT 
    fr.QuestionId,
    fr.Title,
    fr.TotalAnswerScore,
    fr.AverageViewCount,
    COALESCE(fr.TagName, 'No tags') AS Tag,
    COALESCE(fr.UserWithMostBadges, 'No badges') AS UserWithMostBadges,
    COALESCE(fr.BadgeCount, 0) AS BadgeCount
FROM FinalResults fr
ORDER BY fr.TotalAnswerScore DESC NULLS LAST; -- Order by score, putting NULLs last
