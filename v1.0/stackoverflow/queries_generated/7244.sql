WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
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
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(tg.TagName, 'No Tags') AS TagName
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         pt.PostId,
         STRING_AGG(t.TagName, ', ') AS TagName
     FROM 
         PostsTags pt
     JOIN 
         Tags t ON pt.TagId = t.Id
     GROUP BY 
         pt.PostId) tg ON tp.PostId = tg.PostId
ORDER BY 
    tp.UpVotes DESC, tp.CreationDate DESC;
