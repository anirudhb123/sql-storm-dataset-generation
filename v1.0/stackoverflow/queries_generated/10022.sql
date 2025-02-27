-- Performance Benchmarking Query
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(DATEDIFF(second, p.CreationDate, p.LastActivityDate)) AS AvgTimeToActivitySeconds,
        COUNT(DISTINCT bh.Id) AS TotalHistoryChanges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory bh ON p.Id = bh.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.TotalComments,
    ps.TotalVotes,
    ps.UpVotes,
    ps.DownVotes,
    ps.AvgTimeToActivitySeconds,
    ps.TotalHistoryChanges,
    us.UserId,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.MaxReputation
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.PostId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
ORDER BY 
    ps.TotalVotes DESC, ps.TotalComments DESC;
