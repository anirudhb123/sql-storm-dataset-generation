-- Performance benchmark query to analyze the post statistics
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(v.VoteTypeId = 2) AS UpvoteCount,
        AVG(v.VoteTypeId = 3) AS DownvoteCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount,
        p.CreationDate,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    *,
    (UpvoteCount - DownvoteCount) AS NetVoteScore
FROM 
    PostStats
ORDER BY 
    CreationDate DESC;
