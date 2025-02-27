-- Performance benchmarking SQL query to retrieve user statistics and related post information
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT a.Id) AS TotalAnswers,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(v.VoteCount) AS TotalVotes,
    SUM(b.Class) AS TotalBadges,
    t.TagName AS PopularTag,
    t.Count AS TagCount
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 -- Questions only
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN (
    SELECT PostId, COUNT(*) AS VoteCount
    FROM Votes
    GROUP BY PostId
) v ON p.Id = v.PostId
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE u.Reputation > 0
GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate, t.TagName, t.Count
ORDER BY TotalPosts DESC, TotalVotes DESC
LIMIT 100; -- Get top 100 users based on post activity
