WITH RECURSIVE UserReputationCTE AS (
    SELECT
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        LastAccessDate,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Starting point for users with significant reputation

    UNION ALL

    SELECT
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation < ur.Reputation
    WHERE ur.Level < 5 -- Limit to 5 levels of reputation hierarchies
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        STUFF(REPLACE(REPLACE(p.Tags, '<', ''), '>', ''), ',', ', ') AS CleanTags -- Clean the tags formatting
    FROM Posts p
),
PostHistoricalDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pt.Name AS PostType,
        ph.UserId,
        ph.Comment
    FROM PostHistory ph
    JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE ph.CreationDate > '2023-01-01' -- Recent history only
),
TopVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2020-01-01'
    GROUP BY p.Id
    ORDER BY UpVotes DESC
    LIMIT 10 -- Top 10 most voted posts
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate AS UserCreationDate,
    p.Title AS PostTitle,
    p.CleanTags,
    ph.PostHistoryTypeId,
    ph.CreationDate AS HistoryCreationDate,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount
FROM UserReputationCTE u
JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostHistoricalDetails ph ON p.Id = ph.PostId
JOIN PostWithTags pt ON p.Id = pt.PostId
JOIN TopVotedPosts tp ON p.Id = tp.Id
WHERE 
    (ph.Comment IS NOT NULL OR ph.PostHistoryTypeId IN (10, 11)) -- Interested in certain historical actions
    AND tp.UpVotes > 10 -- Filter for popular posts
ORDER BY u.Reputation DESC, tp.UpVotes DESC;
