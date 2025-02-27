WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) DESC) AS Rank
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
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        AuthorName, 
        CreationDate, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.AuthorName,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts p WHERE p.Id = tp.PostId)
WHERE 
    pt.Name = 'Question' OR pt.Name = 'Answer'
ORDER BY 
    tp.UpVoteCount DESC, 
    tp.CommentCount DESC;
