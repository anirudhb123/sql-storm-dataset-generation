-- Performance benchmarking query to assess the number of posts, average votes per post, and distribution of post types

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(v.vote_count) AS AverageVotes,
    SUM(v.vote_count) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS vote_count
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Results of this query can help identify the most common post types and how actively they are engaged with through votes.
