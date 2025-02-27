WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
PostRanks AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CASE 
            WHEN Score >= 20 THEN 'High'
            WHEN Score BETWEEN 10 AND 19 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUserPosts AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        p.Title,
        p.ViewCount,
        p.Score, 
        pu.ScoreCategory
    FROM 
        UserStats us
    JOIN 
        PostRanks p ON us.UserId = p.OwnerUserId
    LEFT JOIN 
        PostRanks pu ON p.PostId = pu.PostId
    WHERE 
        us.Reputation > (SELECT AVG(Reputation) FROM Users)  -- Users above average reputation
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        COUNT(p.Title) AS TotalPosts,
        SUM(CASE WHEN pu.Score >= 20 THEN 1 ELSE 0 END) AS HighScorePosts,
        COALESCE(AVG(pu.ViewCount), 0) AS AverageViewCount
    FROM 
        UserStats us
    LEFT JOIN 
        PostRanks pu ON us.UserId = pu.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation
)
SELECT 
    cs.DisplayName,
    cs.Reputation,
    cs.TotalPosts,
    cs.HighScorePosts,
    cs.AverageViewCount,
    MAX(CASE WHEN ps.ScoreCategory = 'High' THEN 1 ELSE 0 END) AS HasHighScorePost,
    NULLIF(MIN(ps.Score), 0) AS MinScore,  -- NULL if no posts
    STRING_AGG(DISTINCT ps.Title, '; ') AS PostTitles
FROM 
    CombinedStats cs
LEFT JOIN 
    TopUserPosts ps ON cs.UserId = ps.UserId
GROUP BY 
    cs.UserId, cs.DisplayName, cs.Reputation
ORDER BY 
    cs.Reputation DESC, cs.TotalPosts DESC;
