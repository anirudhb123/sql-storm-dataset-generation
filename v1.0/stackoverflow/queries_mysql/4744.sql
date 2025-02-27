
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        PostCount,
        CommentCount,
        BadgeCount,
        @rank := @rank + 1 AS Rank
    FROM 
        UserScores, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC, Upvotes DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        @rn := IF(@prevUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevUserId := p.OwnerUserId
    FROM 
        Posts p, (SELECT @rn := 0, @prevUserId := NULL) r
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 30 DAY)
    ORDER BY 
        p.OwnerUserId, p.LastActivityDate DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.CommentCount,
    tu.BadgeCount,
    rp.Title AS MostRecentPostTitle,
    rp.CreationDate AS MostRecentPostDate,
    rp.Score AS MostRecentPostScore
FROM 
    TopUsers tu
LEFT JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC, tu.Upvotes DESC;
