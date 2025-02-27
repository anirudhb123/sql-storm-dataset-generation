WITH RecursiveCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only Questions

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        Level + 1
    FROM
        Posts p
    INNER JOIN Posts ans ON ans.ParentId = p.Id
    WHERE
        ans.PostTypeId = 2 -- Only Answers
),
PostStatistics AS (
    SELECT
        r.PostId,
        COUNT(*) AS AnswerCount,
        AVG(r.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN r.Score > 0 THEN 1 ELSE 0 END) AS PositiveVotes
    FROM
        RecursiveCTE r
    GROUP BY
        r.PostId
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        COALESCE(SUM(po.AnswerCount), 0) AS TotalAnswers
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostStatistics po ON u.Id = po.PostId
    GROUP BY
        u.Id, u.DisplayName
),
RecentPostStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        COALESCE(ps.AvgViewCount, 0) AS AvgViews,
        COALESCE(ps.PositiveVotes, 0) AS PositiveVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RowNum
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostStatistics ps ON p.Id = ps.PostId
    WHERE
        p.CreationDate >= DATEADD(DAY, -30, GETDATE()) -- Posts created in the last 30 days
)
SELECT
    r.RowNum,
    r.PostId,
    r.Title,
    r.OwnerName,
    r.AvgViews,
    r.PositiveVoteCount,
    u.TotalBadges,
    u.TotalAnswers
FROM
    RecentPostStats r
LEFT JOIN UserStatistics u ON r.OwnerName = u.DisplayName
ORDER BY
    r.RowNum
OPTION (RECOMPILE);
