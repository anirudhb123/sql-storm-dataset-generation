WITH RECURSIVE PostHierarchy AS (
    SELECT Id, Title, ParentId, 1 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT p.Id, p.Title, p.ParentId, ph.Level + 1
    FROM Posts p
    INNER JOIN PostHierarchy ph ON p.ParentId = ph.Id
),
UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
           MAX(p.CreationDate) AS LastActiveDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT p.Id,
           p.Title,
           p.CreationDate,
           COALESCE(v.VoterCount, 0) AS VoteCount,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(pv.UpVotes, 0) AS UpVoteCount,
           COALESCE(pv.DownVotes, 0) AS DownVoteCount,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoterCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN LATERAL (
        SELECT ARRAY_AGG(t.TagName) AS Tags
        FROM Tags t
        WHERE t.Id IN (SELECT unnest(string_to_array(p.Tags, '>')))
    ) t ON TRUE
    GROUP BY p.Id, p.Title, p.CreationDate
),
PostsWithUserActivity AS (
    SELECT ps.*,
           ua.DisplayName AS OwnerDisplayName,
           ua.LastActiveDate
    FROM PostStats ps
    LEFT JOIN UserActivity ua ON ps.OwnerDisplayName = ua.DisplayName
)
SELECT ph.Level,
       ps.Id,
       ps.Title,
       ps.CreationDate,
       ps.VoteCount,
       ps.CommentCount,
       ps.UpVoteCount,
       ps.DownVoteCount,
       ps.Tags,
       pu.LastActiveDate
FROM PostsWithUserActivity ps
JOIN PostHierarchy ph ON ps.Id = ph.Id
WHERE ps.LastActiveDate IS NOT NULL
ORDER BY ph.Level, ps.CreationDate DESC
LIMIT 100;
