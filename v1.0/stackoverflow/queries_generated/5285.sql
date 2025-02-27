WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LatestActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ur.TotalPosts,
    pa.PostId,
    pa.Title,
    pa.TotalComments,
    pa.TotalUpVotes AS PostUpVotes,
    pa.TotalDownVotes AS PostDownVotes,
    pa.AverageScore,
    pa.LatestActivity
FROM 
    UserRankings ur
JOIN 
    PostAggregates pa ON ur.UserId = (SELECT TOP 1 OwnerUserId FROM Posts WHERE Id = pa.PostId ORDER BY CreationDate DESC)
WHERE 
    ur.UserRank <= 10
ORDER BY 
    ur.UserRank, pa.TotalComments DESC;
