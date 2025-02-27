WITH RecursivePostHierarchy AS (
    SELECT Id, Title, ParentId, OwnerUserId, CreationDate, 0 AS Level
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, p.OwnerUserId, p.CreationDate, Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(v.VoteTypeId = 10), 0) AS DeletionVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN a.Id END) AS AnswerCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
AggregatedData AS (
    SELECT 
        r.Id AS PostId,
        r.Title,
        r.Level,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.AnswerCount,
        ur.Reputation,
        ur.BadgeCount
    FROM RecursivePostHierarchy r
    JOIN PostStatistics ps ON r.Id = ps.Id
    JOIN UserReputation ur ON r.OwnerUserId = ur.UserId
)
SELECT 
    a.PostId,
    a.Title,
    a.Level,
    a.UpVotes,
    a.DownVotes,
    a.CommentCount,
    a.AnswerCount,
    a.Reputation,
    a.BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY a.Level ORDER BY a.UpVotes DESC) AS RankByUpVotes,
    CASE 
        WHEN a.BadgeCount > 5 THEN 'Experienced'
        WHEN a.BadgeCount BETWEEN 1 AND 5 THEN 'Novice'
        ELSE 'No Badges'
    END AS UserExperienceLevel
FROM AggregatedData a
WHERE a.UpVotes IS NOT NULL
ORDER BY a.Level, a.UpVotes DESC;
