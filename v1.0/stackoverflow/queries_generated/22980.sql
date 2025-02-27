WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),

TopPosts AS (
    SELECT 
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    WHERE 
        rp.PostRank <= 10
)

SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CloseCount,
    tp.CloseReasons,
    CASE 
        WHEN tp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN tp.Score IS NULL THEN 'Unscored'
        ELSE 'Scored'
    END AS ScoreStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.Title;

WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    u.Id,
    u.DisplayName,
    ubc.BadgeCount,
    CASE 
        WHEN ubc.BadgeCount >= 5 THEN 'Expert'
        WHEN ubc.BadgeCount BETWEEN 1 AND 4 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
WHERE 
    u.Reputation > 1000

UNION ALL

SELECT 
    -1 AS UserId,
    'Community' AS DisplayName,
    COUNT(p.Id) AS BadgeCount,
    'N/A' AS UserLevel
FROM 
    Posts p
WHERE 
    p.OwnerUserId = -1;

WITH TagPostCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    tpc.TagName,
    tpc.PostCount,
    CASE 
        WHEN tpc.PostCount >= 50 THEN 'Popular'
        ELSE 'Less Popular'
    END AS PopularityRank
FROM 
    TagPostCounts tpc
WHERE 
    tpc.PostCount > 0
ORDER BY 
    tpc.PostCount DESC;


