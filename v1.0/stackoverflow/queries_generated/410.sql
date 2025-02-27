WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        pt.Name AS PostType,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
), 
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        PostType,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        PostDetails
    WHERE 
        rn <= 5 -- Fetch top 5 posts per type
)

SELECT 
    p.PostId, 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.PostType,
    p.OwnerDisplayName,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount,
    CASE 
        WHEN p.Score > 0 THEN 'Popular' 
        ELSE 'Unpopular' 
    END AS Popularity,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Votes v
            WHERE v.PostId = p.PostId 
            AND v.VoteTypeId = 1
        ) THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = p.PostId
       AND c.CreationDate >= NOW() - INTERVAL '1 month') AS RecentComments
FROM 
    TopPosts p
ORDER BY 
    p.ViewCount DESC, p.CreationDate DESC
LIMIT 50;
