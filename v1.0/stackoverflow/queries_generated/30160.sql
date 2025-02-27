WITH RecursiveTagCTE AS (
    -- Recursive CTE to find tags and their associated posts
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        p.Id AS PostId,
        p.Title,
        1 AS Level
    FROM 
        Tags t
    JOIN 
        Posts p ON t.ExcerptPostId = p.Id

    UNION ALL

    SELECT 
        t.Id,
        t.TagName, 
        pl.RelatedPostId AS PostId,
        p.Title,
        Level + 1
    FROM 
        RecursiveTagCTE r
    JOIN 
        PostLinks pl ON r.PostId = pl.PostId
    JOIN 
        Posts p ON pl.RelatedPostId = p.Id
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        Level < 5  -- Limit recursion to avoid infinite loop or excessive resources
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
    AVG(u.Reputation) AS AvgReputation,
    STRING_AGG(DISTINCT r.TagName, ', ') AS AssociatedTags,
    COUNT(DISTINCT bh.Id) AS BadgeCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
    SUM(CASE WHEN p.FavoriteCount IS NOT NULL THEN p.FavoriteCount ELSE 0 END) AS TotalFavorites
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
LEFT JOIN 
    RecursiveTagCTE r ON p.Id = r.PostId
WHERE 
    u.Reputation > 100 AND 
    (p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year' OR p.Id IS NULL) -- Filter users with reasonable reputation
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, AvgReputation DESC
LIMIT 100; -- Limit result set to the top 100 users
