WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        0 AS Level,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        Level + 1,
        p2.CreationDate,
        p2.AnswerCount,
        p2.CommentCount,
        p2.ViewCount
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    p.Title,
    r.Level,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    CASE 
        WHEN PH.Score > 0 THEN 'Highly Rated'
        WHEN PH.Score BETWEEN -3 AND 0 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    COUNT(DISTINCT PH.Id) AS Edits,
    DATEDIFF(DAY, MIN(PH.CreationDate), GETDATE()) AS DaysSinceFirstEdit
FROM 
    RecursivePostHierarchy r
INNER JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId
LEFT JOIN 
    PostHistory PH ON r.PostId = PH.PostId
LEFT JOIN 
    Posts p ON PH.PostId = p.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' + t.TagName + '%'
WHERE 
    u.Reputation > 100
GROUP BY 
    u.DisplayName, u.Reputation, r.Title, r.Level
HAVING 
    COUNT(DISTINCT c.Id) > 5 
ORDER BY 
    u.Reputation DESC, r.Level ASC;


### Description of the query:

1. **Common Table Expression (CTE)**: The recursive CTE `RecursivePostHierarchy` builds a tree structure starting from questions and gathers hierarchical data around them.
  
2. **Select Clause**: Main fields selected include user's display name and reputation, post title, the hierarchical level of the post (the level of the question in the answer thread), the count of comments, counts of upvotes and downvotes utilizing conditional aggregation, and categorization of post ratings using a case statement.

3. **String Aggregation**: Tags are aggregated into a comma-separated list by checking if the tags exist in a string.

4. **Joins**: The query uses various types of joins (inner and left) to connect users, comments, votes, post history, and tags to the root post.

5. **Filters**: It filters for users with a reputation above 100 and considers only posts that have more than 5 comments.

6. **Group By and Having**: Aggregates data to summarize interactions for each user and post, ensuring only users satisfying the comment condition are returned.

7. **Ordering**: Finally, returns data ordered by user reputation and hierarchical level.
