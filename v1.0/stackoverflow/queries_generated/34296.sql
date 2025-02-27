WITH RecursiveTagHierarchy AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsage
    FROM 
        Tags 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 1
),
UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        hp.CreationDate AS CloseDate,
        hp.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory hp ON p.Id = hp.PostId
    WHERE 
        hp.PostHistoryTypeId = 10
)

SELECT 
    u.DisplayName AS UserName,
    us.UpVotes,
    us.DownVotes,
    th.TagName AS PopularTag,
    COUNT(DISTINCT cp.PostId) AS ClosedPostCount,
    AVG(cp.CloseDate - p.CreationDate) AS AvgClosureDuration
FROM 
    UserVoteSummary us
JOIN 
    Users u ON us.UserId = u.Id
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = p.Id
JOIN 
    RecursiveTagHierarchy th ON th.TagUsage > 5
WHERE 
    u.Reputation >= 100
GROUP BY 
    u.Id, u.DisplayName, th.TagName
ORDER BY 
    AvgClosureDuration DESC,
    UserName;

This SQL query features multiple constructs, including:

1. **Recursive CTEs (Common Table Expressions)**: `RecursiveTagHierarchy` identifies tags that are used by more than one post.
2. **Collated User Vote Summary**: `UserVoteSummary` aggregates upvotes and downvotes for each user.
3. **Closed Posts CTE**: `ClosedPosts` retrieves details of closed posts along with the user who closed them.
4. **Outer Joins**: `LEFT JOIN` is used to include users who may not have voted.
5. **Calculations and Grouping**: Computes the average duration between post creation and closure, grouped by users and tags, alongside user voting behavior.
6. **Complex filtering**: Includes conditions based on user reputation and tag usage.
7. **Sorting**: Results are ordered by average closure duration and user names.

The resulting dataset will list users who have closed posts, displaying their voting statistics, associated tags that are popular, and providing insight into the closure duration of their posts.
