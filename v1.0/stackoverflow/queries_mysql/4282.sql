
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @rn := IF(@prevOwnerUserId = p.OwnerUserId, @rn + 1, 1) AS rn,
        @prevOwnerUserId := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @rn := 0, @prevOwnerUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS NumberOfPosts,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.NumberOfPosts,
        ua.TotalCommentScore,
        ua.UpvoteCount,
        ua.DownvoteCount,
        @rank := @rank + 1 AS rank
    FROM 
        UserActivity ua,
        (SELECT @rank := 0) AS r
    ORDER BY 
        ua.Reputation DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.NumberOfPosts,
    tu.TotalCommentScore,
    tu.UpvoteCount,
    tu.DownvoteCount,
    COALESCE(rp.Title, 'No Recent Posts') AS RecentPostTitle
FROM 
    TopUsers tu
LEFT JOIN 
    RankedPosts rp ON tu.UserId = rp.PostId
WHERE 
    tu.rank <= 10
ORDER BY 
    tu.Reputation DESC, 
    tu.NumberOfPosts DESC
LIMIT 5 OFFSET 5;
