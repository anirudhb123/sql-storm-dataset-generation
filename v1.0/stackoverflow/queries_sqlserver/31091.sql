
WITH PostActivity AS (
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
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
        v.CreationDate >= DATEADD(month, -6, '2024-10-01')
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(ISNULL(p.CommentCount, 0)) AS TotalComments,
        MAX(p.CreationDate) AS LastPostDate
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
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
    AND ups.LastPostDate >= DATEADD(month, -6, '2024-10-01')
ORDER BY
    ups.TotalScore DESC;
