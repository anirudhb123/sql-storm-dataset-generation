-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves a summary of post statistics combined with user reputation and the number of votes each post received.
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        Score, 
        ViewCount, 
        AnswerCount, 
        CommentCount, 
        OwnerReputation, 
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, VoteCount DESC) AS Rank
    FROM 
        PostStats
)

SELECT 
    *
FROM 
    TopPosts
WHERE 
    Rank <= 10; -- Top 10 posts based on score and vote count
