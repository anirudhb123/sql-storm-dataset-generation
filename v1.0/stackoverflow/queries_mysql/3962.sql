
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(t.TagName, ''), 'No Tag') AS TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT Id, SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts 
         JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                      SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(Tags)
         -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n-1
         WHERE Tags IS NOT NULL) t ON p.Id = t.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, t.TagName
), RecentVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.TagName,
    rp.CommentCount,
    COALESCE(rv.NetVotes, 0) AS NetVotes,
    CASE 
        WHEN rp.Score > 100 AND COALESCE(rv.NetVotes, 0) > 5 THEN 'Highly Engaging'
        WHEN rp.Score <= 100 AND COALESCE(rv.NetVotes, 0) <= 5 THEN 'Moderately Engaging'
        ELSE 'Needs More Attention' 
    END AS EngagementStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
