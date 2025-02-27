WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotesCount,
        COALESCE(AVG(v.BountyAmount) OVER (PARTITION BY p.Id), 0) AS AvgBounty,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentTotal
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '2 years'
)

SELECT 
    up.DisplayName AS UserDisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.CommentTotal,
    CASE 
        WHEN rp.Rank = 1 THEN 'Latest'
        WHEN rp.UpVotesCount > 10 AND rp.AvgBounty > 0 THEN 'Popular with Bounty'
        WHEN rp.CommentTotal > 5 THEN 'Discussions Happening'
        ELSE 'Standard Post'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.PostId = up.Id
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC
OFFSET 2 ROWS
FETCH NEXT 3 ROWS ONLY

UNION ALL

SELECT
    u.DisplayName,
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS Tags,
    NULL AS CommentTotal,
    'No Recent Posts' AS PostStatus
FROM 
    Users u
WHERE 
    NOT EXISTS (SELECT 1 FROM RankedPosts rp WHERE rp.PostId = u.Id)
  AND COALESCE(u.Reputation, 0) < 100
ORDER BY 
    u.Reputation DESC
LIMIT 3;

This SQL query utilizes a Common Table Expression (CTE) called `RankedPosts`, which organizes post data based on several criteria, including tagging, voting, and comments. The main query selects data from this CTE, defining a custom `PostStatus` through case logic. It also includes a `UNION ALL` with a secondary select statement to identify users with no recent posts, showcasing a more elaborate query structure with complexity.
