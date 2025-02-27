-- Performance Benchmarking Query
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' -- Filter to posts created in 2023
    GROUP BY 
        p.Id, u.DisplayName
), 
VoteDetails AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    COALESCE(vd.UpVotes, 0) AS UpVotes,
    COALESCE(vd.DownVotes, 0) AS DownVotes,
    COALESCE(vd.AcceptedVotes, 0) AS AcceptedVotes
FROM 
    PostDetails pd
LEFT JOIN 
    VoteDetails vd ON pd.PostId = vd.PostId
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 100;
