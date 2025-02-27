WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rnk
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
        PostId, 
        Title, 
        OwnerName, 
        CommentCount, 
        UpVotes, 
        DownVotes, 
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        rnk <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    EXTRACT(EPOCH FROM (NOW() - tp.CreationDate)) AS AgeInSeconds
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC, tp.CreationDate DESC;
