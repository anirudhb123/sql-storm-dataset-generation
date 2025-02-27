WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        CAST(0 AS int) AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.Id
)
, UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
, TopQuestions AS (
    SELECT 
        Id,
        Title,
        Score,
        ViewCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RecursivePostCTE
    WHERE 
        CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Top questions from the last year
)
SELECT 
    uq.UserId,
    uq.DisplayName,
    uq.TotalBounty,
    uq.BadgeCount,
    uq.AvgReputation,
    tq.Title AS TopQuestionTitle,
    tq.Score AS TopQuestionScore,
    tq.ViewCount AS TopQuestionViews,
    CASE 
        WHEN tq.Score >= 10 THEN 'High Score'
        WHEN tq.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    UserStats uq
INNER JOIN 
    TopQuestions tq ON uq.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tq.Id)  -- Matching user's top questions
WHERE 
    uq.TotalBounty > (SELECT AVG(TotalBounty) FROM UserStats)  -- Only users above average bounty
ORDER BY 
    uq.TotalBounty DESC, tq.Score DESC
LIMIT 10;

-- This query provides a benchmark of user statistics against their top questions,
-- highlighting users who have earned significant bounties and earned badges for notable 
-- contributions over the last year in a tiered scoring system.
