WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
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
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(trp.Title, 'No Posts') AS LatestPostTitle,
    COALESCE(trp.CreationDate, '1900-01-01') AS LatestPostDate,
    COALESCE(trp.ViewCount, 0) AS LatestPostViewCount,
    COALESCE(trp.CommentCount, 0) AS LatestPostCommentCount,
    COALESCE(trp.UpVotes, 0) AS LatestPostUpVotes,
    COALESCE(trp.DownVotes, 0) AS LatestPostDownVotes,
    CASE 
        WHEN us.Reputation > 1000 THEN 'High'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS ReputationCategory
FROM 
    UserStatistics us
LEFT JOIN 
    TopRankedPosts trp ON us.UserId = trp.PostId
ORDER BY 
    us.Reputation DESC, 
    LatestPostDate DESC;
