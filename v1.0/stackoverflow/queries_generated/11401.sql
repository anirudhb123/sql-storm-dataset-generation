-- Performance benchmarking query for StackOverflow schema

WITH PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        p.OwnerUserId,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2022-01-01' -- Filtering for posts created in the last year
    GROUP BY 
        p.Id, u.Reputation
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.VoteCount,
    pa.BadgeCount,
    pa.OwnerUserId,
    pa.OwnerReputation
FROM 
    PostAnalytics pa
ORDER BY 
    pa.ViewCount DESC
LIMIT 100; -- Limit to top 100 posts by view count for benchmarking
