-- Performance Benchmarking SQL Query

-- This query benchmarks the performance related to post activities, user engagements, and comments on posts.

WITH PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on posts created in the last year
    GROUP BY 
        p.Id, p.PostTypeId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.ViewCount) AS TotalPostViews,
        COUNT(DISTINCT p.Id) AS PostsCreated
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on users created in the last year
    GROUP BY 
        u.Id
)

SELECT 
    pa.PostId,
    pa.PostTypeId,
    pa.TotalComments,
    pa.TotalVotes,
    pa.UpVotes,
    pa.DownVotes,
    pa.DeletionVotes,
    ueng.UserId,
    ueng.TotalPostViews,
    ueng.PostsCreated
FROM 
    PostAggregates pa
JOIN 
    UserEngagement ueng ON pa.PostId = ueng.UserId  -- Join to relate posts with user engagement
ORDER BY 
    pa.TotalVotes DESC, pa.TotalComments DESC;  -- Order by most engaged posts
