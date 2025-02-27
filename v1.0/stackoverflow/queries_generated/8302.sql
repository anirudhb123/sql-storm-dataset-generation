WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000 -- Only active users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    au.DisplayName,
    au.Reputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViews,
    rp.Score AS RecentPostScore,
    rp.CommentCount AS RecentPostComments,
    au.BadgeCount,
    au.UpVotes,
    au.DownVotes
FROM 
    ActiveUsers au
JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
WHERE 
    rp.RecentPostRank = 1 -- Only the most recent post for each user
ORDER BY 
    au.Reputation DESC, rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
