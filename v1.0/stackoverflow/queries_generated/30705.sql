WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.PostTypeId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.ParentId,
        a.PostTypeId,
        ph.Level + 1
    FROM Posts a
    JOIN PostHierarchy ph ON ph.Id = a.ParentId
    WHERE a.PostTypeId = 2 -- Answers
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(bc.BadgeCount, 0) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes
    FROM Users u
    LEFT JOIN BadgeCounts bc ON u.Id = bc.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.Level,
        u.UserId,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS Status
    FROM Posts p
    JOIN PostHierarchy ph ON ph.Id = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
FinalResult AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Author,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        um.BadgeCount,
        pm.Level,
        pm.Status
    FROM PostMetrics pm
    JOIN UserStats um ON pm.UserId = um.UserId
)
SELECT 
    fr.*,
    CONCAT('Post: ', fr.Title, ' by ', fr.Author, ' (Level ', fr.Level, ') - ', fr.Status, ' - Score: ', fr.Score) AS Description
FROM FinalResult fr
ORDER BY fr.Score DESC, fr.CommentCount DESC
LIMIT 100;
