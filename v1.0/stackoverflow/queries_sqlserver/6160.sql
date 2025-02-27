
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.Author,
    ISNULL(pv.UpVotes, 0) AS UpVotes,
    ISNULL(pv.DownVotes, 0) AS DownVotes,
    ISNULL(pc.TotalComments, 0) AS TotalComments
FROM 
    TopPosts tp
LEFT JOIN 
    PostVotes pv ON tp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
