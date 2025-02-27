-- Performance benchmarking query to analyze post statistics, user engagement, and activity

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' -- focus on posts created in the last month
    GROUP BY 
        p.Id, u.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 month' -- users active in the last month
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.OwnerReputation,
    ue.TotalVotes,
    ue.UpVotes,
    ue.DownVotes,
    ps.TotalComments
FROM 
    PostStats ps
LEFT JOIN 
    UserEngagement ue ON ps.OwnerDisplayName = ue.DisplayName
ORDER BY 
    ps.CreationDate DESC; -- sort by most recent posts
