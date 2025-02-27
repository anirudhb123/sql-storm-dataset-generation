-- Performance benchmarking query to analyze post data

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
        AND p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.OwnerReputation,
    vc.UpVotes,
    vc.DownVotes
FROM 
    PostStats ps
LEFT JOIN 
    VoteCounts vc ON ps.PostId = vc.PostId
ORDER BY 
    ps.CreationDate DESC; -- Order by most recent posts
