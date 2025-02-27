
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        u.DisplayName AS Owner, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount, 
        rp.Owner 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostVotes AS (
    SELECT 
        v.PostId, 
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes, 
        COUNT(CASE WHEN v.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Owner,
    pv.UpVotes,
    pv.DownVotes,
    pv.CloseVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
