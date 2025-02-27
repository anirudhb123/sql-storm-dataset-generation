WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -2, GETDATE())
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title,
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.Score, 
        CASE 
            WHEN rp.ScoreRank <= 10 THEN 'Top 10' 
            ELSE 'Other' 
        END AS RankCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 15
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ModerationHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopened
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    mh.LastClosed,
    mh.LastReopened
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.Id = pc.PostId
LEFT JOIN 
    ModerationHistory mh ON tp.Id = mh.PostId
WHERE 
    (mh.LastClosed IS NULL OR mh.LastClosed < mh.LastReopened)
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
