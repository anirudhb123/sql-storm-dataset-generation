-- Performance Benchmarking Query
-- The following query retrieves a summary of posts, user engagement metrics, and badge counts, 
-- which can be utilized to benchmark performance in terms of post activity and user interactions.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    p.CommentCount,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    u.Views AS UserViews,
    COALESCE(badgeCount.BadgeCount, 0) AS TotalBadges,
    COALESCE(voteCount.UpVotes, 0) AS TotalUpVotes,
    COALESCE(voteCount.DownVotes, 0) AS TotalDownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) badgeCount ON u.Id = badgeCount.UserId
LEFT JOIN 
    (SELECT 
         PostId, 
         SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
         SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
         Votes 
     GROUP BY 
         PostId) voteCount ON p.Id = voteCount.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Adjusting the time frame for more recent posts
ORDER BY 
    p.CreationDate DESC;
