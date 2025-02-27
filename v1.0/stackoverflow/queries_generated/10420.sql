-- Performance benchmarking query to analyze various aspects of Stack Overflow posts

WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(b.Reputation) AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Limiting to posts created in the last year for benchmarking
    GROUP BY 
        p.Id, u.DisplayName
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    OwnerDisplayName,
    OwnerReputation
FROM 
    PostAnalytics
ORDER BY 
    ViewCount DESC;  -- Ordering by highest view count for performance insights
