WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.Score,
        p2.ViewCount,
        p2.OwnerUserId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE cte ON p2.ParentId = cte.PostId
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViews,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags,
    (SELECT COUNT(*) 
     FROM Comments c
     WHERE c.PostId IN (SELECT PostId FROM RecursivePostCTE)) AS TotalComments,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', t.TagName, '%'))
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9  -- BountyClose
GROUP BY 
    u.Id
ORDER BY 
    TotalQuestions DESC
LIMIT 10;

-- This query generates insights into users based on their posted questions, 
-- including their associated tags, number of comments to their questions, 
-- total badges received, and total bounty amounts.
