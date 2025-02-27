-- Performance benchmarking query on Stack Overflow schema

-- This query retrieves the count of posts by type, total votes received, and average views per post for performance analysis

WITH PostStats AS (
    SELECT
        pt.Name AS PostType,
        COUNT(p.Id) AS PostCount,
        SUM(v.VoteTypeId IN (2)) AS TotalUpvotes, -- Count of upvotes
        SUM(v.VoteTypeId IN (3)) AS TotalDownvotes, -- Count of downvotes
        AVG(p.ViewCount) AS AverageViews -- Average view count per post
    FROM
        Posts p
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        pt.Name
)

SELECT
    PostType,
    PostCount,
    TotalUpvotes,
    TotalDownvotes,
    AverageViews
FROM
    PostStats
ORDER BY
    PostCount DESC;
