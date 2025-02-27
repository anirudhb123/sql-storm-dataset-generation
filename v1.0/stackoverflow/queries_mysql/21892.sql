
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) AS UpVotesCount,  
        (SELECT COUNT(v2.Id) FROM Votes v2 WHERE v2.PostId = p.Id AND v2.VoteTypeId = 3) AS DownVotesCount  
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS PostHistoryNames  
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS RecentViews,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(MAX(p.LastActivityDate), DATE('1900-01-01')) AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    up.DisplayName,
    up.RecentViews,
    up.BadgeCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.UpVotesCount,
    pp.DownVotesCount,
    phs.LastEditDate,
    phs.EditCount,
    phs.PostHistoryNames
FROM 
    UserActivity up
INNER JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON pp.PostId = phs.PostId
WHERE 
    up.RecentViews IS NOT NULL 
    AND pp.Rank <= 5 
    AND pp.ViewCount > 0
ORDER BY 
    up.RecentViews DESC,
    (pp.UpVotesCount - pp.DownVotesCount) DESC
LIMIT 50;
