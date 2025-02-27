-- Performance benchmarking query to assess the number of posts, votes, and comments over a specific period
WITH PostStats AS (
    SELECT 
        p.PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(v.VoteTypeId IN (2)) AS TotalUpVotes,  -- Assuming 2 = UpMod
        SUM(v.VoteTypeId IN (3)) AS TotalDownVotes,  -- Assuming 3 = DownMod
        COALESCE(SUM(c.Id), 0) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' AND p.CreationDate < '2024-01-01'  -- Adjust the range as needed
    GROUP BY 
        p.PostTypeId
)
SELECT 
    pt.Name AS PostType,
    ps.TotalPosts,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    ps.TotalComments
FROM 
    PostTypes pt
JOIN 
    PostStats ps ON pt.Id = ps.PostTypeId
ORDER BY 
    ps.TotalPosts DESC;
