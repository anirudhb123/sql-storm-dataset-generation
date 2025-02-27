WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes -- Upvotes - Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)
SELECT 
    up.DisplayName,
    up.Reputation,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.NetVotes,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers up ON rp.OwnerUserId = up.Id
WHERE 
    rp.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY 
    rp.Score DESC, up.Reputation DESC
LIMIT 10
UNION ALL
SELECT 
    'Total Retrieved' AS DisplayName, 
    COUNT(*) AS Reputation,
    NULL AS Title,
    NULL AS Score,
    NULL AS CommentCount,
    NULL AS NetVotes,
    NULL AS PostCategory 
FROM 
    RankedPosts
WHERE 
    Score IS NOT NULL;
