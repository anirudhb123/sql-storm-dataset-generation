WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation 
    HAVING 
        COUNT(p.Id) > 5 -- Users with more than 5 posts
), 
PostStatistics AS (
    SELECT 
        r.PoсtId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.CommentCount,
        r.UpvoteCount,
        r.DownvoteCount,
        u.DisplayName,
        ROW_NUMBER() OVER (ORDER BY r.Score DESC, r.CommentCount DESC) AS ScoreRank
    FROM 
        RecentPostActivity r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM 
    PostStatistics ps
LEFT JOIN 
    TopUsers tu ON ps.OwnerUserId = tu.UserId
WHERE 
    ps.RecentPostRank <= 5 -- Limit to the top 5 recent posts per user
ORDER BY 
    ps.ScoreRank
LIMIT 50;
