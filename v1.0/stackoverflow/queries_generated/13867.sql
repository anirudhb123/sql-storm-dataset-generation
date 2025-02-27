-- Performance Benchmarking Query
SELECT 
    pt.Name AS PostType,
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS NumberOfPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(COALESCE(votes.VoteCount, 0)) AS AverageVotes,
    AVG(badges.BadgeCount) AS AverageBadges,
    AVG(cmnt.CommentCount) AS AverageComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) votes ON p.Id = votes.PostId
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) badges ON p.OwnerUserId = badges.UserId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) cmnts ON p.Id = cmnts.PostId
GROUP BY 
    pt.Name
ORDER BY 
    NumberOfPosts DESC;
