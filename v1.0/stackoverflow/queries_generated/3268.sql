WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        PostRank
    FROM 
        PostDetails
    WHERE 
        PostRank <= 5
)
SELECT 
    t.OwnerDisplayName,
    t.Title,
    t.CreationDate,
    COALESCE(t.UpVotes - t.DownVotes, 0) AS NetVotes,
    CASE 
        WHEN t.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS CommentStatus
FROM 
    TopPosts t
ORDER BY 
    t.CreationDate DESC
LIMIT 10;

SELECT 
    DISTINCT pt.Name AS PostTypeName, 
    COUNT(p.Id) AS TotalPosts
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
HAVING 
    COUNT(p.Id) > 10
UNION ALL
SELECT 
    'Total Users' AS PostTypeName,
    COUNT(DISTINCT u.Id)
FROM 
    Users u 
WHERE 
    u.Reputation > 1000;
