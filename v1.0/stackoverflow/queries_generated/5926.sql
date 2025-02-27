WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostType,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT *
    FROM PostDetails
    WHERE RowNum <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.PostType,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.HistoryCount
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC;
