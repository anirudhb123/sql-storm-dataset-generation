WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        p.OwnerUserId,
        CAST(ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS INT) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        p.OwnerUserId,
        CAST(ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS INT) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) as BadgeCount,
        STRING_AGG(b.Name, ', ') as BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostScoreSummary AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalPostScore,
        COUNT(CASE WHEN p.AnswerCount > 0 THEN 1 END) AS AnsweredQuestions,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    b.BadgeNames,
    ps.TotalPostScore,
    ps.AnsweredQuestions,
    ps.AvgViews,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.UserPostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostScoreSummary ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    RecursivePostCTE r ON u.Id = r.OwnerUserId
WHERE 
    (r.UserPostRank <= 5 OR r.UserPostRank IS NULL)
ORDER BY 
    ps.TotalPostScore DESC,
    r.CreationDate DESC
LIMIT 100;

This SQL query combines multiple constructs, including:
- Recursive Common Table Expressions (CTEs) to derive post details in relation to users.
- CTE for counts and aggregations related to user badges.
- A CTE to calculate the overall summary statistics for posts like total scores and view averages.
- LEFT JOINs to link users, their badges, and their post statistics.
- A correlated row number ranking to find the top posts per user.
- COALESCE for handling NULL values.
- Aggregate functions such as COUNT and AVG.
- The use of `STRING_AGG()` for concatenating badge names into a single field.
