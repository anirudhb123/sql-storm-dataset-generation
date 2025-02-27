WITH RECURSIVE UserActivity AS (
    -- This CTE retrieves all posts and their authors
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        1 AS Level
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 5000 -- filter users with high reputation

    UNION ALL

    -- This part of the CTE joins comments made by the users and their corresponding posts
    SELECT 
        u.Id,
        u.DisplayName,
        p.Id,
        c.CreationDate,
        c.Score,
        NULL AS ViewCount,
        Level + 1
    FROM Users u
    JOIN Comments c ON u.Id = c.UserId
    JOIN Posts p ON c.PostId = p.Id
    WHERE u.Reputation > 5000
),

UserVotes AS (
    -- CTE to aggregate votes per user on posts
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    GROUP BY v.UserId
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COALESCE(u.VoteCount, 0) AS TotalVotes,
        COALESCE(u.UpVotes, 0) AS UpVotes,
        COALESCE(u.DownVotes, 0) AS DownVotes
    FROM Posts p
    LEFT JOIN UserVotes u ON p.OwnerUserId = u.UserId
)

SELECT 
    ua.DisplayName AS Author,
    pd.Title,
    pd.TotalVotes,
    pd.UpVotes,
    pd.DownVotes,
    pd.CreationDate,
    ROW_NUMBER() OVER (PARTITION BY ua.DisplayName ORDER BY pd.CreationDate DESC) AS ActivityRank,
    COUNT(c.Id) AS CommentCount,
    AVG(V.score) AS AverageScore
FROM UserActivity ua
JOIN PostDetails pd ON ua.PostId = pd.PostId
LEFT JOIN Comments c ON pd.PostId = c.PostId
LEFT JOIN Votes V ON pd.PostId = V.PostId
WHERE ua.Level = 1  -- focusing only on posts
GROUP BY ua.DisplayName, pd.Title, pd.TotalVotes, pd.UpVotes, pd.DownVotes, pd.CreationDate
ORDER BY ActivityRank, TotalVotes DESC;
