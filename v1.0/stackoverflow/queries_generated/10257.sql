-- Performance Benchmarking SQL Query

-- This query retrieves the total number of posts, average scores, and user reputation
-- along with the related tags and number of votes for each post type from the Stack Overflow database.

WITH PostStats AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.Score) AS AvgScore,
        SUM(COALESCE(v.UserId, 0)) AS TotalVotes,
        SUM(COALESCE(user.Reputation, 0)) AS TotalReputation
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users user ON p.OwnerUserId = user.Id
    GROUP BY 
        pt.Name
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
)

SELECT 
    ps.PostType,
    ps.TotalPosts,
    ps.AvgScore,
    ps.TotalVotes,
    ps.TotalReputation,
    COALESCE(ts.TagPostCount, 0) AS TagPostCount
FROM 
    PostStats ps
LEFT JOIN 
    TagStats ts ON ts.TagPostCount > 0
ORDER BY 
    ps.TotalPosts DESC;
