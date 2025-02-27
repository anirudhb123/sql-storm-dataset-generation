
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT cr.Name ORDER BY cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
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
