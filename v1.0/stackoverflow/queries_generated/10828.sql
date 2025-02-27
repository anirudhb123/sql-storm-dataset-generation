-- Performance benchmarking query
WITH PostCounts AS (
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
UserActivity AS (
    SELECT 
        u.DisplayName AS UserName, 
        COUNT(c.Id) AS TotalComments, 
        SUM(vote.VoteTypeId = 2) AS TotalUpVotes, 
        SUM(vote.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes vote ON u.Id = vote.UserId
    GROUP BY 
        u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName, 
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)

SELECT 
    pc.PostType, 
    pc.TotalPosts,
    ua.UserName, 
    ua.TotalComments, 
    ua.TotalUpVotes, 
    ua.TotalDownVotes,
    pt.TagName AS PopularTag,
    pt.TotalViews
FROM 
    PostCounts pc
JOIN 
    UserActivity ua ON ua.TotalComments > 0
JOIN 
    PopularTags pt ON pt.TotalViews > 0
ORDER BY 
    pc.TotalPosts DESC;
