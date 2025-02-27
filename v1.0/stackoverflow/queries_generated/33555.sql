WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        CAST(u.Reputation AS BIGINT) AS AccumulatedReputation,
        0 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 0

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation,
        ur.AccumulatedReputation + u.Reputation,
        Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE ur ON u.Id = ur.UserId
    WHERE 
        Level < 3
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(ur.AccumulatedReputation, 0) AS TotalReputation,
    COUNT(p.Id) AS PostCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    CASE 
        WHEN COUNT(p.Id) > 0 THEN 
            ROUND(SUM(p.Score) / COUNT(p.Id), 2)
        ELSE 
            0
    END AS AveragePostScore,
    STRING_AGG(DISTINCT CASE 
        WHEN t.TagName IS NOT NULL THEN t.TagName 
        END, ', ') AS Tags
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(Tags, ',')) AS TagName
        FROM 
            Posts
        WHERE 
            Posts.Id = p.Id
    ) t ON TRUE
LEFT JOIN 
    UserReputationCTE ur ON u.Id = ur.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, ur.AccumulatedReputation
ORDER BY 
    TotalReputation DESC
LIMIT 10;

-- Calculate the number of posts with actions and user activity
SELECT 
    ph.UserId,
    COUNT(DISTINCT ph.PostId) AS ModifiedPostCount,
    MAX(ph.CreationDate) AS LastModifiedDate
FROM 
    PostHistory ph
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6, 10, 12) -- Title, Body edits, Closures, Deletions
GROUP BY 
    ph.UserId
HAVING 
    COUNT(DISTINCT ph.PostId) > 5
ORDER BY 
    LastModifiedDate DESC;

This query uses a recursive CTE to accumulate the reputation for users, retrieves average post scores along with user activity like post creation/modification, and involves filtering, grouping, and string aggregation. It also showcases outer joins for including related data like tags. The second part of the query checks for the activity of users in terms of post modifications and actions taken.
