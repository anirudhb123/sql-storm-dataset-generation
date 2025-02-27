WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS LatestPostOrder
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- only questions
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        p.Title,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::jsonb->>'CloseReasonId'::int = cr.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId, p.Title
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        COALESCE(MAX(p.ViewCount), 0) AS MaxPostViewCount,
        AVG(p.ViewCount) FILTER (WHERE p.OwnerUserId = u.Id) AS AvgPostViewCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.ViewCount,
    r.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    hs.CloseReopenCount AS HistoricalCloseReopenCount,
    pst.CloseReasons,
    u.MaxPostViewCount,
    u.AvgPostViewCount,
    CASE 
        WHEN r.LatestPostOrder <= 10 THEN 'Recent Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    RankedPosts r
JOIN 
    UserStats u ON r.OwnerUserId = u.UserId
LEFT JOIN 
    PostHistories hs ON r.PostId = hs.PostId
WHERE 
    (u.GoldBadges > 2 OR r.ViewCount > u.AvgPostViewCount)
    AND (EXISTS (SELECT 1 FROM Comments c2 WHERE c2.PostId = r.PostId AND c2.CreationDate >= NOW() - INTERVAL '1 month'))
ORDER BY 
    r.ViewCount DESC,
    r.CreationDate DESC
LIMIT 50;
