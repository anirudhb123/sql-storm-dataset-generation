WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UsersEngaged
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Only considering Questions
    GROUP BY t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only considering Questions
    GROUP BY p.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgScore,
    ts.UsersEngaged,
    ub.BadgeCount,
    ub.BadgeNames,
    pe.CommentCount,
    pe.VoteCount
FROM TagStatistics ts
JOIN UserBadges ub ON ub.UserId IN (SELECT DISTINCT p.OwnerUserId 
                                     FROM Posts p 
                                     WHERE p.Tags LIKE CONCAT('%<', ts.TagName, '>%' ))
JOIN PostEngagement pe ON pe.PostId IN (SELECT p.Id 
                                         FROM Posts p 
                                         WHERE p.Tags LIKE CONCAT('%<', ts.TagName, '>%' ))
ORDER BY ts.TotalViews DESC, ts.AvgScore DESC;
