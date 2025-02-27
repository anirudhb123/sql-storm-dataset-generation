-- Performance Benchmarking SQL Query
WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts, 
        SUM(Score) AS TotalScore, 
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserReputation AS (
    SELECT 
        Reputation, 
        COUNT(*) AS UserCount
    FROM 
        Users
    GROUP BY 
        Reputation
),
TagStats AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount
    FROM 
        Tags
    GROUP BY 
        TagName
),
VoteStats AS (
    SELECT 
        VoteTypeId, 
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        VoteTypeId
)
SELECT 
    p.PostTypeId, 
    pc.TotalPosts, 
    pc.TotalScore, 
    pc.TotalViews,
    ur.Reputation, 
    ur.UserCount,
    ts.TagName, 
    ts.TagCount,
    vs.VoteTypeId, 
    vs.TotalVotes
FROM 
    PostCounts pc
JOIN 
    PostTypes p ON p.Id = pc.PostTypeId
JOIN 
    UserReputation ur ON ur.Reputation > 50 -- Filtering for users with reputation above 50
JOIN 
    TagStats ts ON ts.TagCount >= 10 -- Filtering tags used in at least 10 posts
JOIN 
    VoteStats vs ON vs.TotalVotes > 5 -- Only including vote types with significant activity
ORDER BY 
    pc.TotalPosts DESC, 
    pc.TotalScore DESC;
