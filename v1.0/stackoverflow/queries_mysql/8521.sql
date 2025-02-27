
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@prev_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_id := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id,
        (SELECT @row_number := 0, @prev_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName
),
PostHistoryWithVotes AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerDisplayName,
        p.CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostWithComments p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerDisplayName, p.CommentCount
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    ph.Score,
    ph.ViewCount,
    ph.OwnerDisplayName,
    ph.CommentCount,
    ph.UpVotes,
    ph.DownVotes,
    ph.LastClosedDate,
    (SELECT COUNT(*) FROM PostHistoryWithVotes x WHERE x.Score > ph.Score) + 1 AS GlobalRank
FROM 
    PostHistoryWithVotes ph
ORDER BY 
    ph.Score DESC, ph.ViewCount DESC;
