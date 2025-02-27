WITH RecursiveTagCount AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        WikiPostId,
        1 AS Level
    FROM 
        Tags
    WHERE 
        Count > 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        t.ExcerptPostId,
        t.WikiPostId,
        rt.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagCount rt ON rt.ExcerptPostId = t.Id 
    WHERE 
        t.Count > 0 AND rt.Level < 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
)

SELECT 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
    COALESCE(SUM(ps.Upvotes), 0) AS TotalUpvotes,
    COALESCE(SUM(ps.Downvotes), 0) AS TotalDownvotes,
    tt.TagName,
    COUNT(DISTINCT ps.PostId) AS PostsWithTagCount
FROM 
    UserActivity u
LEFT JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    PostStats ps ON p.Id = ps.PostId
LEFT JOIN 
    Tags tt ON tt.WikiPostId = p.Id
GROUP BY 
    u.UserId, u.DisplayName, u.Reputation, tt.TagName
HAVING 
    COALESCE(SUM(ps.Upvotes), 0) - COALESCE(SUM(ps.Downvotes), 0) > 10
ORDER BY 
    TotalComments DESC, u.Reputation DESC
LIMIT 10;

This query performs the following:

1. **Recursive CTE `RecursiveTagCount`:** This builds a recursive structure to count tags with a specified condition (level and count).
  
2. **CTE `UserActivity`:** Collects user statistics including their reputation, total post counts, upvotes, and downvotes.

3. **CTE `PostStats`:** Aggregates statistics for each post, including comments and vote counts.

4. **Final SELECT:** Gathers user data, counts of posts they have made, and details related to tags. It filters users with a net positive voting score and sorts them based on their activity and reputation.

5. **Complexity and Usage of Various SQL Constructs:** The query demonstrates usage of CTEs, outer joins, aggregating functions, grouping and order by, correlated relationships, and conditional aggregation.
