WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        CommentCount, 
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank = 1
    ORDER BY 
        Score DESC,
        ViewCount DESC
    LIMIT 10
)
SELECT 
    tr.PostId,
    tr.Title,
    tr.CreationDate,
    tr.Score,
    tr.ViewCount,
    tr.CommentCount,
    tr.VoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    TopRankedPosts tr
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tr.PostId)
ORDER BY 
    tr.ViewCount DESC, 
    tr.Score DESC;
