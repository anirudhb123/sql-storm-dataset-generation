WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
)

SELECT 
    u.DisplayName AS UserName, 
    u.Reputation, 
    r.PostId, 
    r.Title, 
    r.CreationDate, 
    r.Score, 
    r.ViewCount, 
    r.Level,
    COALESCE(tblBadges.BadgeCount, 0) AS BadgeCount,
    COUNT(c.Id) AS CommentCount,
    AVG(v.Score) FILTER (WHERE vt.Name = 'UpMod') AS AverageUpVotes
FROM 
    Users u 
LEFT JOIN 
    RecursiveCTE r ON u.Id = r.OwnerUserId 
LEFT JOIN 
    (SELECT 
         UserId, 
         COUNT(*) AS BadgeCount 
     FROM 
         Badges 
     GROUP BY 
         UserId) AS tblBadges ON u.Id = tblBadges.UserId 
LEFT JOIN 
    Comments c ON r.PostId = c.PostId 
LEFT JOIN 
    Votes v ON r.PostId = v.PostId 
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id 
WHERE 
    r.Level <= 2 -- Limit to top level and one nested level of answers
GROUP BY 
    u.DisplayName, u.Reputation, r.PostId, r.Title, 
    r.CreationDate, r.Score, r.ViewCount, r.Level, tblBadges.BadgeCount
HAVING 
    COUNT(c.Id) > 0 -- Only include posts with at least one comment
ORDER BY 
    r.Score DESC, r.ViewCount DESC;

This query performs the following actions:

1. Defines a recursive Common Table Expression (CTE) to navigate through questions and their respective answers.
2. Joins the Users table with the result of the CTE to gather information about post owners.
3. It uses a LEFT JOIN to obtain badge counts for users, as well as the number of comments associated with each post.
4. It calculates the average upvotes for posts using a conditional aggregate, filtering the VoteTypes based on whether the vote type is an upvote.
5. Applies a HAVING clause to filter out posts without comments.
6. Finally, it orders the results by post score and view count.

This serves as a comprehensive benchmark for investigating the relationship between users, their posts, and interactions like comments and votes.
