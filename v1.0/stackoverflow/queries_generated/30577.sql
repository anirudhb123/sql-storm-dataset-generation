WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        Level + 1
    FROM Posts p
    INNER JOIN Posts parent ON p.ParentId = parent.Id
    WHERE parent.PostTypeId = 1 -- Link only to Questions
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),

PostStats AS (
    SELECT 
        p.Id,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS DownVotes,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) - SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS Score
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY p.Id
)

SELECT 
    rp.Id AS QuestionId,
    rp.Title,
    u.DisplayName AS Owner,
    up.BadgeCount,
    up.BadgeNames,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.Score,
    rp.AcceptedAnswerId,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    RANK() OVER (PARTITION BY rp.OwnerUserId ORDER BY ps.Score DESC) AS UserRanking
FROM RecursivePosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges up ON u.Id = up.UserId
LEFT JOIN PostStats ps ON rp.Id = ps.Id
WHERE rp.Level = 0
ORDER BY ps.Score DESC, rp.CreationDate DESC
LIMIT 100;
