WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate) AS RankByDate,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2),
            0
        ) AS UpVotes,
        COALESCE(
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3),
            0
        ) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId, ph.PostId
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    us.BadgeCount,
    rs.PostId,
    rs.Title,
    rs.Score,
    rs.ViewCount,
    rs.RankByScore,
    rs.RankByDate,
    phs.LastClosedDate,
    phs.LastReopenedDate,
    phs.DeleteUndeleteCount,
    CASE 
        WHEN phs.DeleteUndeleteCount > 5 THEN 'Active' 
        ELSE 'Inactive' 
    END AS ActivityStatus,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Posts p
            WHERE p.OwnerUserId = u.Id
            AND p.CreationDate < DATEADD(MONTH, -3, GETDATE())
            AND p.Score < 0
        ) THEN 'At Risk'
        ELSE 'Stable'
    END AS Stability
FROM 
    UserStatistics us
JOIN 
    Users u ON u.Id = us.UserId
JOIN 
    RankedPosts rs ON rs.PostId = (
        SELECT TOP 1 PostId 
        FROM RankedPosts rp 
        WHERE rp.RankByScore = 1 AND rp.PostId = rs.PostId
    )
LEFT JOIN 
    PostHistorySummary phs ON phs.UserId = u.Id
WHERE 
    us.Reputation > 1000 -- Only show users with reputation greater than 1000
ORDER BY 
    ActivityStatus DESC, 
    Stability ASC, 
    u.Reputation DESC;
This query selects user statistics, ranking their posts by score and creation date while also incorporating their badge counts. Connection to `PostHistory` is made to summarize their activities, delineating between active and inactive users and assessing stability based on older posts. The result set is ordered to highlight the most relevant users based on activity status and reputation.
