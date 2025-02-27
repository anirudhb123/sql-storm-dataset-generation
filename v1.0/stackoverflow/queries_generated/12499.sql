-- Performance Benchmarking Query

WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserActivity AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
TagUsage AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Tags 
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '>'::text)::int[])
    GROUP BY 
        Tags.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    pc.PostTypeId,
    pc.TotalPosts,
    pc.AcceptedAnswers,
    ua.UserId,
    ua.TotalVotes,
    ua.UpVotes,
    ua.DownVotes,
    tu.TagName,
    tu.PostCount
FROM 
    PostCounts pc
FULL OUTER JOIN 
    UserActivity ua ON pc.PostTypeId = ua.UserId
LEFT JOIN 
    TagUsage tu ON ua.UserId = (SELECT MIN(UserId) FROM UserActivity)
ORDER BY 
    pc.TotalPosts DESC, ua.TotalVotes DESC;
