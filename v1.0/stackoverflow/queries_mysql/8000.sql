
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CommentCount, 
        UpVoteCount, 
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        VoteRank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    (tp.UpVoteCount - tp.DownVoteCount) AS NetVoteScore,
    (SELECT 
         GROUP_CONCAT(t.TagName SEPARATOR ', ') 
     FROM 
         Tags t 
     WHERE 
         t.ExcerptPostId = tp.PostId) AS AssociatedTags
FROM 
    TopPosts tp
ORDER BY 
    NetVoteScore DESC, 
    tp.CommentCount DESC;
