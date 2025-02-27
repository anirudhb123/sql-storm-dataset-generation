
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COALESCE(NULLIF(p.Body, ''), 'No content') AS PostBody,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
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
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2023-01-01'
        AND p.Body IS NOT NULL
    GROUP BY 
        p.Id, 
        p.Title, 
        p.Tags, 
        p.Body, 
        u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        PostBody,
        OwnerDisplayName,
        CommentCount,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.PostBody,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    'Post by ' + tp.OwnerDisplayName + 
    ' has ' + CAST(tp.CommentCount AS VARCHAR(10)) + ' comments, ' + 
    CAST(tp.AnswerCount AS VARCHAR(10)) + ' answers, ' + 
    CAST(tp.UpVotes AS VARCHAR(10)) + ' upvotes, and ' + 
    CAST(tp.DownVotes AS VARCHAR(10)) + ' downvotes.' AS Summary
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC;
