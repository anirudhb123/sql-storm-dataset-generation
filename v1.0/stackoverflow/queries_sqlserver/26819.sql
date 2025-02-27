
WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        
        LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', '')) - LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>', '')) + 1 AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY ph.PostId
),
EnabledTesting AS (
    SELECT 
        pts.PostId, 
        pts.Title, 
        pts.CreationDate, 
        pts.Score,
        pts.ViewCount, 
        pts.TagCount, 
        pts.OwnerDisplayName, 
        pts.CommentCount, 
        pts.BadgeCount,
        phs.EditCount,
        phs.LastEditDate
    FROM PostTagStats pts
    LEFT JOIN PostHistoryStats phs ON pts.PostId = phs.PostId
)
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Score, 
    ViewCount, 
    TagCount, 
    OwnerDisplayName, 
    CommentCount, 
    BadgeCount, 
    COALESCE(EditCount, 0) AS EditCount,
    LastEditDate
FROM EnabledTesting
ORDER BY Score DESC, ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
