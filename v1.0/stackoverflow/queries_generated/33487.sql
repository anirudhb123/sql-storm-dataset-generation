WITH UserPostStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.Id IS NOT NULL AND vt.Id = 2) AS UpVoteCount,
        SUM(v.Id IS NOT NULL AND vt.Id = 3) AS DownVoteCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        u.Id
), 
RecentBadges AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        MAX(b.Date) AS LastAwardDate
    FROM
        Badges b
    WHERE
        b.Date > NOW() - INTERVAL '1 year'
    GROUP BY
        b.UserId
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM
        PostHistory ph
    INNER JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        PostCount,
        UpVoteCount,
        DownVoteCount,
        LastPostDate,
        BadgeNames,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, UpVoteCount DESC) AS UserRank
    FROM
        UserPostStatistics ups
    LEFT JOIN
        RecentBadges rb ON ups.UserId = rb.UserId
)
SELECT
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    tu.LastPostDate,
    tu.BadgeNames,
    phs.HistoryTypes,
    phs.HistoryCount
FROM
    TopUsers tu
LEFT JOIN
    PostHistorySummary phs ON tu.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = phs.PostId)
WHERE
    tu.UserRank <= 10
    AND (tu.LastPostDate BETWEEN NOW() - INTERVAL '30 days' AND NOW() OR tu.BadgeNames IS NOT NULL)
ORDER BY
    tu.PostCount DESC,
    tu.UpVoteCount DESC;

This SQL query performs the following functions:
- It uses Common Table Expressions (CTEs) to calculate user post statistics, aggregate recent badges, and summarize post history.
- It incorporates window functions to rank users based on their post count and upvotes.
- It implements multiple `LEFT JOIN`s for gathering related information.
- The final selection includes filtering criteria, specifically targeting the top 10 users based on performance metrics and recent activity.
