WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts)
    WHERE 
        u.Reputation > 0 -- Filter for users with positive reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

TagActivity AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT p.OwnerUserId) AS UserCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)

SELECT 
    ua.DisplayName AS UserName,
    ua.Reputation AS UserReputation,
    ua.PostCount AS TotalPosts,
    ua.CommentCount AS TotalComments,
    ua.UpVoteCount AS TotalUpVotes,
    ua.DownVoteCount AS TotalDownVotes,
    ta.TagName AS PopularTag,
    ta.PostCount AS PostsWithTag,
    ta.UserCount AS UsersEngagedWithTag,
    ta.TotalViews AS TotalTagViews,
    ta.AvgScore AS AveragePostScore
FROM 
    UserActivity ua
JOIN 
    TagActivity ta ON ua.PostCount > 0
ORDER BY 
    ua.Reputation DESC, 
    ta.PostCount DESC
LIMIT 10; -- Limiting to top 10 users based on reputation and their engagement with popular tags
