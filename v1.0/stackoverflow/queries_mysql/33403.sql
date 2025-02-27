
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserRanking AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @rank := @rank + 1 AS Rank
    FROM 
        Users u, (SELECT @rank := 0) r
    ORDER BY 
        u.Reputation DESC
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%') 
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId, ph.Comment
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Score,
    ur.Rank AS UserRank,
    pt.TagName,
    cr.CloseReason,
    cr.CloseCount,
    (SELECT COUNT(*) FROM CloseReasons cr2 WHERE cr2.CloseReason = cr.CloseReason AND ph.Score > (SELECT ph2.Score FROM PostHierarchy ph2 WHERE ph2.PostId = cr.PostId)) + 1 AS ReasonRank
FROM 
    PostHierarchy ph
JOIN 
    Users u ON ph.PostId = u.Id
JOIN 
    UserRanking ur ON u.Id = ur.UserId
LEFT JOIN 
    PostLinks pl ON pl.PostId = ph.PostId
LEFT JOIN 
    PopularTags pt ON pl.RelatedPostId = pt.PostCount
LEFT JOIN 
    CloseReasons cr ON cr.PostId = ph.PostId
WHERE 
    ph.Level < 3 
ORDER BY 
    ph.Score DESC, ur.Rank;
