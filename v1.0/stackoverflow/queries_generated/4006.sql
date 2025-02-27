WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold Badges
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.BadgeCount,
    ARRAY_AGG(DISTINCT p.Title) AS Titles,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Users u
LEFT JOIN 
    UserBadges us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts p ON p.OwnerUserId = u.Id AND p.ScoreRank <= 3
LEFT JOIN 
    PostComments pc ON pc.PostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, us.BadgeCount, pc.CommentCount
HAVING 
    COUNT(DISTINCT p.Id) > 0
ORDER BY 
    u.Reputation DESC, TotalComments DESC
LIMIT 10;
