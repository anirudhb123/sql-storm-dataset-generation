WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- UpVotes and DownVotes
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.RankScore,
        CASE 
            WHEN rp.RankScore <= 5 THEN 'Top 5'
            ELSE 'Other'
        END AS RankCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS ClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    COALESCE(DATEDIFF(CURRENT_TIMESTAMP, tp.CreationDate)::INTEGER, -1) AS DaysSinceCreation,
    ph.ClosedDate,
    ph.CloseCount,
    tp.RankCategory,
    CASE 
        WHEN tp.ViewCount IS NULL THEN 'Unknown Views'
        ELSE 'Known Views'
    END AS ViewStatus
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryAggregated ph ON tp.PostId = ph.PostId
WHERE 
    (ph.ClosedDate IS NULL OR ph.CloseCount < 3)
ORDER BY 
    tp.RankCategory, tp.Score DESC;
