WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        SUM(p.Score) OVER (PARTITION BY p.OwnerUserId) AS TotalOwnerScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
HighScorers AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS HighScoreRank
    FROM 
        RankedPosts
    WHERE 
        Score > 100
),
CloseReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        hs.Title,
        hs.Score,
        cr.CloseReason
    FROM 
        UserStatistics us
    LEFT JOIN HighScorers hs ON us.UserId = hs.OwnerUserId
    LEFT JOIN CloseReasons cr ON hs.PostId = cr.PostId
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.Reputation,
    fs.PostCount,
    fs.Title,
    fs.Score,
    COALESCE(fs.CloseReason, 'Not Closed') AS CloseReason,
    CASE 
        WHEN fs.Reputation IS NULL OR fs.PostCount = 0 THEN 'Newbie'
        WHEN fs.Reputation > 1000 THEN 'Experienced'
        ELSE 'Regular'
    END AS UserTier,
    CASE 
        WHEN fs.Score IS NULL THEN 'No Posts'
        WHEN fs.Score < 50 THEN 'Low Scorer'
        WHEN fs.Score BETWEEN 50 AND 200 THEN 'Medium Scorer'
        ELSE 'High Scorer'
    END AS PostPerformance
FROM 
    FinalStats fs
ORDER BY 
    fs.Reputation DESC NULLS LAST, fs.Score DESC NULLS LAST;
