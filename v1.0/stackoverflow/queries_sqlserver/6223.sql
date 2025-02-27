
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
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
        v.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
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
    ISNULL(pv.UpVotes, 0) AS UpVotes,
    ISNULL(pv.DownVotes, 0) AS DownVotes,
    ISNULL(pv.CloseVotes, 0) AS CloseVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
