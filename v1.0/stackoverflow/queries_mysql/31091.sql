
WITH RECURSIVE PostActivity AS (
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
        @row_num := IF(@current_user = p.OwnerUserId, @row_num + 1, 1) AS ActivityRank,
        @current_user := p.OwnerUserId
    FROM
        Posts p,
        (SELECT @row_num := 0, @current_user := NULL) AS vars
    WHERE
        p.CreationDate >= DATE('2024-10-01') - INTERVAL 1 YEAR
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
        @row_num := IF(@current_user = pa.OwnerUserId, @row_num + 1, 1) AS ActivityRank,
        @current_user := pa.OwnerUserId
    FROM
        PostActivity pa
    JOIN
        Votes v ON v.PostId = pa.PostId,
        (SELECT @row_num := 0, @current_user := NULL) AS vars
    WHERE
        v.CreationDate >= DATE('2024-10-01') - INTERVAL 6 MONTH
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(IFNULL(p.CommentCount, 0)) AS TotalComments,
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
    AND ups.LastPostDate >= DATE('2024-10-01') - INTERVAL 6 MONTH
ORDER BY
    ups.TotalScore DESC;
