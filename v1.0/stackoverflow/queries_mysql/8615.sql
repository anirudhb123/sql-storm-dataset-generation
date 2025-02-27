
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
RecentVotes AS (
    SELECT 
        v.PostId, 
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        v.PostId
),
PostHistories AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) AND 
        ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 6 MONTH
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.CreationDate, 
    rp.ViewCount, 
    rp.AnswerCount, 
    rp.CommentCount, 
    rp.OwnerDisplayName, 
    COALESCE(rv.TotalVotes, 0) AS TotalVotes, 
    COALESCE(ph.EditCount, 0) AS EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
