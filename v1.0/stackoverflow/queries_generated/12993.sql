-- Performance Benchmarking Query
-- This query benchmarks the performance of various operations involving posts, users, and votes

-- Step 1: Count total posts by post type
WITH PostCount AS (
    SELECT 
        pt.Name AS PostType, 
        COUNT(p.Id) AS TotalPosts
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
),

-- Step 2: Calculate total votes for each post
TotalVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE 
            WHEN vt.Name = 'UpMod' THEN 1 
            WHEN vt.Name = 'DownMod' THEN -1 
            ELSE 0 
        END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        p.Id
)

-- Step 3: Final output combining post count and votes
SELECT 
    pc.PostType,
    pc.TotalPosts,
    COALESCE(SUM(tv.VoteScore), 0) AS TotalVoteScore
FROM 
    PostCount pc
LEFT JOIN 
    Posts p ON pc.PostType = (SELECT Name FROM PostTypes WHERE Id = p.PostTypeId)
LEFT JOIN 
    TotalVotes tv ON p.Id = tv.PostId
GROUP BY 
    pc.PostType, pc.TotalPosts
ORDER BY 
    pc.TotalPosts DESC;
