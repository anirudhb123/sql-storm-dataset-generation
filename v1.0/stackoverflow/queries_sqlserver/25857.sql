
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.ViewCount, 
        p.CreationDate, 
        p.OwnerUserId,
        u.DisplayName AS OwnerName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount
    FROM Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag
    JOIN Tags t ON t.TagName = tag.value
    GROUP BY p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        SUM(ISNULL(b.Class, 0)) AS TotalBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerName,
    ISNULL(ptc.TagCount, 0) AS TagCount,
    ISNULL(phs.EditCount, 0) AS EditCount,
    ISNULL(phs.LastEditDate, NULL) AS LastEditDate,
    ISNULL(ur.TotalBadges, 0) AS OwnerTotalBadges
FROM RankedPosts rp
LEFT JOIN PostTagCounts ptc ON rp.PostId = ptc.PostId 
LEFT JOIN PostHistorySummary phs ON rp.PostId = phs.PostId
LEFT JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
WHERE rp.Rank = 1
ORDER BY rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
