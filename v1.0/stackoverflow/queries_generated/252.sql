WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS Upvotes,  
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(b.Count, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS Count
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(rp.CommentCount, 0) AS CommentCount
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    rp.UserPostRank <= 5
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 10;
