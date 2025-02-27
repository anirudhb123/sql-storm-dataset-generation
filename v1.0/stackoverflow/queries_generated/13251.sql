-- Performance benchmarking query to analyze user engagement on posts and their contributions
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes -- Count of Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    CommentCount,
    UpVotes,
    DownVotes,
    (PostCount + CommentCount) AS TotalEngagement,
    (UpVotes - DownVotes) AS EngagementScore
FROM 
    UserEngagement
ORDER BY 
    TotalEngagement DESC
LIMIT 10; -- Limit to top 10 users by engagement
