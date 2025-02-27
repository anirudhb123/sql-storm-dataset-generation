-- Performance Benchmarking Query
WITH UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalPositivePosts,
        SUM(CASE WHEN p.Score <= 0 THEN 1 ELSE 0 END) AS TotalNegativePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalPositivePosts,
    u.TotalNegativePosts,
    u.AverageScore,
    p.PostId,
    p.TotalVotes,
    p.TotalUpVotes,
    p.TotalDownVotes
FROM 
    UserPostStatistics u
JOIN 
    PostVoteStatistics p ON p.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
ORDER BY 
    u.TotalPosts DESC, p.TotalVotes DESC;
