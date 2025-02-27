WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(bp.Views), 0) AS TotalViews,
        COALESCE(SUM(bp.Score), 0) AS TotalScore,
        COUNT(DISTINCT bp.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts bp ON u.Id = bp.OwnerUserId 
        AND bp.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
LatestPost AS (
    SELECT 
        DISTINCT ON (p.OwnerUserId) 
        p.OwnerUserId,
        p.Title,
        p.CreationDate
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
BadgeCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        us.TotalViews,
        us.TotalScore,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        lp.Title AS LatestPostTitle,
        lp.CreationDate AS LatestPostDate
    FROM 
        Users u
    INNER JOIN 
        UserScores us ON u.Id = us.UserId
    LEFT JOIN 
        BadgeCount bc ON u.Id = bc.UserId
    LEFT JOIN 
        LatestPost lp ON u.Id = lp.OwnerUserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalViews,
    ua.TotalScore,
    ua.BadgeCount,
    COALESCE(ua.LatestPostTitle, 'No Posts Yet') AS LatestPostTitle,
    COALESCE(ua.LatestPostDate, 'N/A') AS LatestPostDate
FROM 
    UserActivity ua
WHERE 
    ua.TotalScore > (SELECT AVG(TotalScore) FROM UserScores)
    AND ua.BadgeCount > (SELECT AVG(BadgeCount) FROM BadgeCount)
ORDER BY 
    ua.TotalViews DESC, 
    ua.TotalScore DESC
LIMIT 10;
