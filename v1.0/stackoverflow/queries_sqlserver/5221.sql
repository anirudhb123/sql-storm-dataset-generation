
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownvoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ',') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryLog AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(DAY, 30, 0)
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    ub.BadgeNames,
    (SELECT COUNT(*) FROM PostHistoryLog phl WHERE phl.PostId = rp.PostId) AS HistoryCount
FROM 
    RecentPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = CAST(ub.UserId AS VARCHAR(255))
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC 
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
