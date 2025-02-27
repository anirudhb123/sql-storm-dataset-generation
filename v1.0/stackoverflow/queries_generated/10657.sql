-- Performance Benchmarking Query

-- This query benchmarks the performance of posting activities by retrieving 
-- the count of posts, average score, and the number of votes grouped by 
-- post types, ordered by the number of posts.

WITH PostMetrics AS (
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Count of Downvotes
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        pt.Name
)

SELECT 
    PostTypeName,
    PostCount,
    AverageScore,
    UpVotes,
    DownVotes
FROM 
    PostMetrics
ORDER BY 
    PostCount DESC;
