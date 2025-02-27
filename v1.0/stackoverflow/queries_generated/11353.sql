-- Performance benchmarking query
-- This query retrieves the count of posts, average score, and average view count per user, along with the maximum and minimum vote counts for each user.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    MAX(v.VoteCount) AS MaxVoteCount,
    MIN(v.VoteCount) AS MinVoteCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(Id) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC;
