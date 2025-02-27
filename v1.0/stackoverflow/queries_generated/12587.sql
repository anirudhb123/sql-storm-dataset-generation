-- Performance benchmarking query for analyzing post activity and user engagement.

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,  -- Upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount, -- Downvotes
        COUNT(b.Id) AS BadgeCount,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN a.Id END) AS AnswerCount -- Answers for questions
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.BadgeCount,
    ps.AnswerCount
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 100; -- Limit to the top 100 posts based on score and views
