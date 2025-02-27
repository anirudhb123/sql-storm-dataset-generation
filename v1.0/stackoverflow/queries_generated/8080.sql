WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostID, Title, CreationDate, Score, OwnerDisplayName, CommentCount,
        UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
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
        WHEN tp.Score >= 100 THEN 'High Score'
        WHEN tp.Score >= 50 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
