WITH Recursive_Posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Recursive_Posts rp ON p.ParentId = rp.PostId
)

SELECT 
    u.DisplayName AS Author,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS TotalBadges,
    SUM(v.BountyAmount) AS TotalBounty,
    SUM(CASE 
        WHEN v.VoteTypeId IN (2, 8) THEN 1 
        WHEN v.VoteTypeId = 3 THEN -1 
        ELSE 0 
    END) AS NetScore,
    AVG(DATEDIFF(second, p.CreationDate, p.LastActivityDate)) AS AvgTimeToActivity,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         string_to_array(substring(Tags, 2, length(Tags)-2), '><') AS TagArray
     FROM 
         Posts) AS tagPosts ON p.Id = tagPosts.PostId
LEFT JOIN 
    UNNEST(tagPosts.TagArray) AS t(TagName) ON t.TagName IS NOT NULL
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 10 
ORDER BY 
    TotalPosts DESC
LIMIT 10
OFFSET 5;

