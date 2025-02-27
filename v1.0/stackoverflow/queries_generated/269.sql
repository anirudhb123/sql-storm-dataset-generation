WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) as rn,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
    COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
    COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    rp.rn = 1
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    TotalViews DESC

UNION ALL

SELECT 
    'Total Contributions' AS UserDisplayName,
    COUNT(DISTINCT p.Id),
    SUM(p.ViewCount),
    AVG(p.Score),
    NULL,
    NULL,
    NULL
FROM 
    Posts p
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year';

WITH PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    ph.PostId,
    STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
    COUNT(*) AS TotalChanges,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount,
    MAX(ph.LastChangeDate) AS LatestChange
FROM 
    PostHistorySummary ph
JOIN 
    Posts p ON ph.PostId = p.Id
GROUP BY 
    ph.PostId
ORDER BY 
    TotalChanges DESC;
