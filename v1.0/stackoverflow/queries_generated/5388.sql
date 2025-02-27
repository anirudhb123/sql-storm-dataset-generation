WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Owner,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    (tp.UpVotes - tp.DownVotes) AS NetVotes
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC;
