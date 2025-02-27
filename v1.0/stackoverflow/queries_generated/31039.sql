WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id, 
        Reputation, 
        CreationDate, 
        DisplayName,
        Views,
        UpVotes,
        DownVotes,
        0 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Starting point for "active" users

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation, 
        u.CreationDate, 
        u.DisplayName,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5  -- Limiting the depth to avoid infinite recursion
), 

RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),

PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Filtering to only Questions
    GROUP BY p.Id, p.Title
)

SELECT 
    u.Id AS UserId, 
    u.DisplayName AS UserName, 
    ur.Reputation AS UserReputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount
FROM UserReputationCTE ur
JOIN Users u ON ur.Id = u.Id
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1  -- Get the most recent post
LEFT JOIN PostInteractions pi ON rp.Id = pi.PostId
WHERE ur.Reputation >= 1000  -- User must be considered active
ORDER BY ur.Reputation DESC, RecentPostDate DESC NULLS LAST;  -- Order by reputation, then post date
