
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, OwnerDisplayName, CommentCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1 
)

SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    CASE 
        WHEN tp.Score >= 50 THEN 'High Score'
        WHEN tp.Score BETWEEN 20 AND 49 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 10;
