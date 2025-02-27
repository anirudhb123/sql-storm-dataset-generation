WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.OwnerDisplayName
),
TopPosts AS (
    SELECT 
        *,
        COALESCE(BadgeCount, 0) AS TotalBadges
    FROM 
        PostWithBadges
    WHERE 
        Rank <= 5
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalPostReport AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.TotalBadges,
        COALESCE(cph.CloseCount, 0) AS TotalCloseVotes
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedPostHistory cph ON tp.PostId = cph.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    TotalBadges,
    TotalCloseVotes,
    CASE 
        WHEN TotalCloseVotes > 0 THEN 'Closed'
        WHEN TotalBadges > 3 THEN 'Badged'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FinalPostReport
ORDER BY 
    Score DESC, TotalBadges DESC;
