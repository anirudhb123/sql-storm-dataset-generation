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
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP) 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        OwnerDisplayName, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
SELECT 
    tp.Title, 
    tp.OwnerDisplayName, 
    tp.CommentCount, 
    tp.UpVotes - tp.DownVotes AS NetVotes, 
    tp.CreationDate,
    PH.Name AS PostHistoryType
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate = (SELECT MAX(ph2.CreationDate) FROM PostHistory ph2 WHERE ph2.PostId = tp.PostId)
ORDER BY 
    tp.Score DESC;
