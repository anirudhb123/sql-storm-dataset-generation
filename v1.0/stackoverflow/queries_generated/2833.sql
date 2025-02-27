WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.LastAccessDate) AS LastActive
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    ur.UserId,
    ur.Reputation,
    ur.BadgeCount,
    ur.LastActive,
    COALESCE(v.VoteCount, 0) AS TotalVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top Post' 
        ELSE 'Regular Post' 
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2  -- Counting upvotes
JOIN 
    UserReputation ur ON ur.UserId = rp.PostId
WHERE 
    ur.Reputation > 1000
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;

