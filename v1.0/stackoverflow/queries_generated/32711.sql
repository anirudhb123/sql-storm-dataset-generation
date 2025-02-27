WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        0 AS Depth
    FROM Posts p
    WHERE p.PostTypeId = 1  -- We'll start with questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.Score,
        a.CreationDate,
        Depth + 1
    FROM Posts a
    INNER JOIN Posts q ON a.ParentId = q.Id
    INNER JOIN RecursivePostCTE r ON r.Id = q.Id
    WHERE a.PostTypeId = 2  -- Only include answers
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.Title AS QuestionTitle,
    r.Score AS QuestionScore,
    p.CommentCount,
    p.TotalUpvotes,
    p.TotalDownvotes,
    ub.BadgeCount,
    ub.BadgeNames,
    CASE 
        WHEN r.Depth > 0 THEN 'Has Answers'
        ELSE 'No Answers'
    END AS AnswerStatus,
    CASE 
        WHEN p.RecentPostRank <= 3 THEN 'Active User'
        ELSE 'Infrequent User'
    END AS UserActivity
FROM RecursivePostCTE r
JOIN Users u ON r.OwnerDisplayName = u.DisplayName
JOIN PostStatistics p ON r.Id = p.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
ORDER BY u.Reputation DESC, r.Score DESC
LIMIT 50;
