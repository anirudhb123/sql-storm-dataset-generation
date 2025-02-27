
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostCounts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostAggregates AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cc.CloseCount, 0) AS CloseCount,
        COALESCE(cc.ReopenCount, 0) AS ReopenCount,
        bu.BadgeCount,
        bu.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        ClosedPostCounts cc ON rp.PostId = cc.PostId
    LEFT JOIN 
        BadgedUsers bu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bu.UserId)
    WHERE 
        rp.rn <= 3  
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.CloseCount,
    pa.ReopenCount,
    pa.BadgeCount,
    pa.HighestBadgeClass,
    CASE 
        WHEN pa.CloseCount = 0 AND pa.ReopenCount > 0 THEN 'Reopened'
        WHEN pa.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    PostAggregates pa 
LEFT JOIN 
    (SELECT 
         SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
         p.Id as PostId
     FROM 
         Posts p
     INNER JOIN 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON pa.PostId = t.PostId
GROUP BY 
    pa.PostId, pa.Title, pa.CreationDate, pa.CommentCount, pa.CloseCount, pa.ReopenCount, pa.BadgeCount, pa.HighestBadgeClass
ORDER BY 
    pa.CommentCount DESC
LIMIT 100;
