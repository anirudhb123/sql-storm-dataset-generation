
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.PostTypeId IN (1, 2)
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
VotesSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        COUNT(*) AS TotalVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    IFNULL(vs.UpVotesCount, 0) AS UpVotesCount,
    IFNULL(vs.DownVotesCount, 0) AS DownVotesCount,
    IFNULL(vs.TotalVotesCount, 0) AS TotalVotesCount
FROM 
    TopPosts tp
LEFT JOIN 
    VotesSummary vs ON tp.PostId = vs.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
