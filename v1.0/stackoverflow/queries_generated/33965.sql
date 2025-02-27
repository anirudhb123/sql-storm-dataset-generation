WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, 0 AS Level
    FROM Users
    WHERE Id IN (SELECT OwnerUserId FROM Posts WHERE Posts.Score > 100)

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id -- Assuming a relationship exists
)

, PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.CreationDate,
        p.LastActivityDate,
        CASE 
            WHEN p.Score > 50 THEN 'High'
            WHEN p.Score BETWEEN 21 AND 50 THEN 'Medium'
            ELSE 'Low'
        END AS PopularityCategory
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.VoteCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.PopularityCategory,
    pa.CreationDate,
    pa.LastActivityDate
FROM 
    UserHierarchy u
JOIN 
    PostAnalytics pa ON pa.VoteCount > 5 -- Filter for posts with more than 5 votes
WHERE 
    pa.PopularityCategory = 'High'
ORDER BY 
    u.Reputation DESC, pa.VoteCount DESC;
