WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.Score, p.ViewCount, p.CreationDate
), HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10 -- Only top 10 by score for each post type
), AggregatedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgePoints,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBountyAmount
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), LatestPostByUser AS (
    SELECT 
        pu.UserId,
        pu.PostId,
        pu.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pu.UserId ORDER BY pu.CreationDate DESC) AS rn
    FROM 
        Posts pu
)

SELECT 
    up.DisplayName AS UserName,
    u.TotalBadgePoints,
    u.TotalPosts,
    u.TotalBountyAmount,
    p.Title AS PostTitle,
    p.Score AS PostScore,
    p.CommentCount AS PostCommentCount,
    p.ScoreCategory,
    l.PostId AS LatestPostId,
    l.CreationDate AS LatestPostDate
FROM 
    AggregatedUsers u
    LEFT JOIN HighScorePosts p ON u.TotalPosts > 0
    LEFT JOIN LatestPostByUser l ON u.UserId = l.UserId AND l.rn = 1
WHERE 
    u.TotalBadgePoints > 0 -- Only users with badges
ORDER BY 
    u.TotalBadgePoints DESC,
    p.Score DESC;
