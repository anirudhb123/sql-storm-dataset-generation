
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01 12:34:56') AS DATETIME)
        AND p.Score > 0
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
        RankByScore <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    ISNULL(pvc.UpVotes, 0) AS UpVotes,
    ISNULL(pvc.DownVotes, 0) AS DownVotes,
    (ISNULL(pvc.UpVotes, 0) - ISNULL(pvc.DownVotes, 0)) AS NetVotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
