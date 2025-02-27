WITH recursive PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        p.CommentCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS ActivityRank
    FROM
        Posts p
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    UNION ALL
    SELECT
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.PostTypeId,
        pa.Score,
        pa.OwnerUserId,
        pa.AnswerCount,
        pa.CommentCount,
        pa.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pa.OwnerUserId ORDER BY pa.CreationDate DESC) AS ActivityRank
    FROM
        PostActivity pa
    JOIN
        Votes v ON v.PostId = pa.PostId
    WHERE
        v.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.CommentCount) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id
)
SELECT
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalAnswers,
    ups.TotalComments,
    ups.LastPostDate,
    ht.Name AS HighScoresType
FROM
    UserPostStats ups
LEFT JOIN
    PostHistory ph ON ups.UserId = ph.UserId
INNER JOIN
    PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
WHERE
    ups.TotalScore > 100
    AND ups.LastPostDate >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY
    ups.TotalScore DESC;

WITH LatestBadgeCounts AS (
    SELECT
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM
        Badges b
    WHERE
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY
        b.UserId
),
CombinedData AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        COALESCE(lbc.BadgeCount, 0) AS BadgeCount,
        ups.TotalPosts,
        ups.TotalScore,
        ups.TotalViews,
        ups.TotalAnswers,
        ups.TotalComments,
        COALESCE(pt.Name, 'No Badge') AS TopBadge
    FROM
        UserPostStats ups
    LEFT JOIN
        LatestBadgeCounts lbc ON ups.UserId = lbc.UserId
    LEFT JOIN
        Badges bd ON ups.UserId = bd.UserId
    LEFT JOIN
        (SELECT
            UserId,
            MAX(Name) AS Name
         FROM
            Badges b
         GROUP BY
            UserId) pt ON ups.UserId = pt.UserId
)
SELECT
    UserId,
    DisplayName,
    TotalPosts,
    TotalScore,
    TotalViews,
    TotalAnswers,
    TotalComments,
    BadgeCount,
    TopBadge
FROM
    CombinedData
WHERE
    BadgeCount > 0
ORDER BY
    TotalScore DESC;
