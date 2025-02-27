WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
), TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
), PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
        JOIN Votes v ON p.Id = v.PostId
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, vt.Name
), FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        tp.CommentCount,
        pv.VoteType,
        pv.VoteCount
    FROM 
        TopPosts tp
        LEFT JOIN PostVoteDetails pv ON tp.PostId = pv.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    JSON_AGG(JSON_BUILD_OBJECT('VoteType', VoteType, 'VoteCount', VoteCount)) AS VoteDetails
FROM 
    FinalResults
GROUP BY 
    PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName, CommentCount
ORDER BY 
    Score DESC, CreationDate DESC;
