
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.CommentCount,
    r.UpVotes,
    r.DownVotes,
    CASE 
        WHEN r.ViewRank = 1 THEN 'Most Viewed'
        ELSE 'Normal'
    END AS ViewCategory,
    COALESCE(u.Reputation, 0) AS UserReputation,
    COALESCE(u.BadgeCount, 0) AS BadgeCount
FROM 
    RankedPosts r
LEFT JOIN 
    UserReputation u ON r.OwnerUserId = u.UserId
WHERE 
    r.CommentCount > 10 OR u.Reputation > 500
ORDER BY 
    r.ViewCount DESC, u.Reputation DESC
LIMIT 50;
