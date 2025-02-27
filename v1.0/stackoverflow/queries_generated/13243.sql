-- Performance Benchmark Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(AVG(v.VoteTypeId = 2), 0) AS Upvotes,  -- Assuming VoteTypeId = 2 is UpMod
        COALESCE(AVG(v.VoteTypeId = 3), 0) AS Downvotes, -- Assuming VoteTypeId = 3 is DownMod
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Upvotes,
    ps.Downvotes,
    ps.CommentCount,
    ps.BadgeCount
FROM 
    PostStats ps
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;  -- Limit to top 100 posts based on view count
