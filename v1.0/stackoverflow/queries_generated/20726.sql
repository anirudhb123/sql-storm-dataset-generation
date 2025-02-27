WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

BadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        b.UserId
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.Upvotes,
    up.Downvotes,
    bu.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    UserReputation up
LEFT JOIN 
    BadgedUsers bu ON up.UserId = bu.UserId
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.UserPostRank = 1 -- Select latest question
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    up.Reputation > 1000
    AND (bu.BadgeCount IS NULL OR bu.BadgeCount > 2) -- Users with either no Gold badges or more than 2 Gold badges
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate ASC;

-- Query checks for:
-- 1. Only considers questions posted in the last year by active users (reputation > 1000).
-- 2. Includes users' upvotes and downvotes totals, filtered for users with varying gold badges.
-- 3. Also ranks users by the most recent question they've posted and the number of comments that post has received.
-- 4. Utilizes CTEs for clean structuring and readability, along with outer joins and window functions for rich internal logic.
