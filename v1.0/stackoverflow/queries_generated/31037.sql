WITH RecursiveUserCTE AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        0 AS Level
    FROM Users
    WHERE Id = 1  -- starting point for recursive CTE, change as necessary

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        Level + 1
    FROM Users AS u
    INNER JOIN RecursiveUserCTE AS r ON r.Id = u.Id
    WHERE Level < 5  -- limit recursion depth
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownvoteCount,
    CASE 
        WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAge,

    -- Using window functions to rank posts by score within their tags
    RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS ScoreRank,

    -- Joining Posts with the Users table
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,

    -- Using LEFT JOIN to fetch additional user data
    CASE 
        WHEN u.Location IS NOT NULL THEN u.Location
        ELSE 'Location not specified'
    END AS UserLocation

FROM Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
JOIN RecursiveUserCTE r ON u.Id = r.Id
WHERE p.ViewCount > 50  -- filtering to only include posts with more than 50 views
AND p.Score IS NOT NULL
ORDER BY p.CreationDate DESC
LIMIT 100;

-- The query utilizes CTE, aggregates, UI Case statements, 
-- subqueries, window functions, and joins to create an elaborate reporting structure.
