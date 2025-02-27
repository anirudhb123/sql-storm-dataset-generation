-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        PostLinks pl ON pl.RelatedPostId = p.Id
    GROUP BY 
        t.TagName
),
VoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ups.UserId,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.TotalViews,
    ups.AvgScore,
    tu.TagName,
    tu.TagCount,
    vs.TotalVotes,
    vs.Upvotes,
    vs.Downvotes
FROM 
    UserPostStats ups
LEFT JOIN 
    TagUsage tu ON tu.TagCount > 0
LEFT JOIN 
    VoteStats vs ON vs.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId)
ORDER BY 
    ups.Reputation DESC
LIMIT 100;
