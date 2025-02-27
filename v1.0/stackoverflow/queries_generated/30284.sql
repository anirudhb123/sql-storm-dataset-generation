WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, 1 AS Level
    FROM Tags
    WHERE IsRequired = 1
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, th.Level + 1
    FROM Tags t
    JOIN PostLinks pl ON t.Id = pl.RelatedPostId
    JOIN TagHierarchy th ON pl.PostId = th.Id
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT CASE WHEN pt.Id = 1 THEN p.Id END) AS AnswerCount, -- only count answers for questions
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RecentActivity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.BadgeCount,
    ub.BadgeNames,
    (SELECT STRING_AGG(th.TagName, ', ') FROM TagHierarchy th WHERE th.Id IN (SELECT unnest(string_to_array(p.Tags, '<>'))::int)) AS Tags -- Extracting tags from string and aggregating them
FROM PostStatistics ps
LEFT JOIN Users u ON ps.PostId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE ps.RecentActivity <= 5 -- Get top 5 recent activities per user
ORDER BY ps.UpVotes DESC, ps.CommentCount DESC
LIMIT 50;

