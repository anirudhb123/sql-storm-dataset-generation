WITH RecentPostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetUpvotes,
        ROUND((p.Score::decimal / NULLIF(p.ViewCount, 0)), 3) AS ScorePerView,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 3600 AS AgeInHours,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM
        Posts p
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY
        p.Id
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM
        Users u
    LEFT JOIN
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id
),
FlaggedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosed,
        MAX(c.Reputation) AS HighestCommenterReputation
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY
        p.Id
)
SELECT
    rpa.PostId,
    rpa.Title AS PostTitle,
    rpa.Score,
    rpa.ViewCount,
    rpa.NetUpvotes,
    rpa.ScorePerView,
    rpa.AgeInHours,
    TOP.DisplayName AS TopUser,
    TOP.PostCount AS UserPostCount,
    TOP.TotalBadgeCount,
    TOP.TotalScore AS UserTotalScore,
    fp.CommentCount,
    CASE
        WHEN fp.IsClosed = 1 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    fp.HighestCommenterReputation
FROM
    RecentPostActivity rpa
JOIN
    TopUsers TOP ON rpa.PostId = TOP.UserId
JOIN
    FlaggedPosts fp ON rpa.PostId = fp.PostId
WHERE
    rpa.AgeInHours < 24
    AND rpa.ScorePerView IS NOT NULL
    AND (fp.CommentCount > 0 OR TOP.TotalScore > 0)
ORDER BY
    rpa.ScorePerView DESC,
    TOP.TotalScore DESC,
    rpa.AgeInHours ASC
LIMIT 50;
