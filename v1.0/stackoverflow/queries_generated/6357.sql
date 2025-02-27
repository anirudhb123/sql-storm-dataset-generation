WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000 -- Only users with reputation greater than 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.TotalScore,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.RankByScore
WHERE 
    rp.RankByScore <= 5 -- Top 5 posts per user
ORDER BY 
    us.TotalScore DESC, rp.Score DESC;
