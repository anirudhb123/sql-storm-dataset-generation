WITH RECURSIVE PostHierarchy AS (
    SELECT p.Id AS PostId, p.Title, p.ParentId, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting with questions
    UNION ALL
    SELECT p.Id, p.Title, p.ParentId, ph.Level + 1
    FROM Posts p
    JOIN PostHierarchy ph ON p.ParentId = ph.PostId
),
PostVoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BadgePoints
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE((pvs.UpVotes - pvs.DownVotes), 0) AS NetVotes,
    ur.DisplayName,
    ur.BadgePoints,
    MAX(CASE WHEN p.CreationDate < NOW() - INTERVAL '6 months' THEN 'Old Post' ELSE 'Recent Post' END) AS PostAge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM PostHierarchy ph
LEFT JOIN Posts p ON ph.PostId = p.Id
LEFT JOIN PostVoteSummary pvs ON ph.PostId = pvs.PostId
LEFT JOIN Users ur ON p.OwnerUserId = ur.Id
LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))::int)  -- Parsing tags
WHERE ur.Reputation > 100  -- Only users with reputation greater than 100
GROUP BY ph.PostId, ph.Title, ph.Level, ur.DisplayName, ur.BadgePoints
ORDER BY ph.Level, NetVotes DESC;
