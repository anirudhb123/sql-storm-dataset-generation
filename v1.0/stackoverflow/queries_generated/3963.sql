WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS total_posts
    FROM 
        Posts p
)

SELECT 
    u.DisplayName,
    u.Reputation,
    pp.Title,
    pp.ViewCount,
    pp.CreationDate,
    CASE 
        WHEN pp.rnk = 1 THEN 'Most Viewed'
        ELSE 'Other Posts'
    END AS PostCategory,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pp.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.Id AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    Users u
LEFT JOIN 
    RankedPosts pp ON u.Id = pp.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
WHERE 
    pp.ViewCount > 100
    AND pp.rnk <= 2
ORDER BY 
    u.Reputation DESC, pp.ViewCount DESC;

-- Additional complex filter
WITH PostTags AS (
    SELECT 
        p.Id AS PostId, 
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::varchar[]) AS tag ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    pp.*, 
    pt.TagsList
FROM 
    RankedPosts pp
LEFT JOIN 
    PostTags pt ON pp.Id = pt.PostId
WHERE 
    pp.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year')

