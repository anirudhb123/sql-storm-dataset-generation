WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS AuthorName
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        (SUM(p.Score) / NULLIF(COUNT(p.Id), 0)) AS AvgScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        COUNT(*) AS ClosureCount
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
    GROUP BY
        ph.PostId
),
UserPostWithClosure AS (
    SELECT
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.QuestionCount,
        us.AnswerCount,
        us.AvgScore,
        COALESCE(cp.ClosureCount, 0) AS ClosureCount
    FROM
        UserStats us
    LEFT JOIN
        ClosedPosts cp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
)
SELECT
    upw.UserId,
    upw.DisplayName,
    upw.TotalPosts,
    upw.QuestionCount,
    upw.AnswerCount,
    upw.AvgScore,
    upw.ClosureCount,
    ARRAY_AGG(rp.Title ORDER BY rp.CreationDate DESC) AS RecentPostTitles
FROM
    UserPostWithClosure upw
LEFT JOIN
    RankedPosts rp ON upw.UserId = rp.OwnerUserId AND rp.Rank <= 5
GROUP BY
    upw.UserId, upw.DisplayName, upw.TotalPosts, upw.QuestionCount, upw.AnswerCount, upw.AvgScore, upw.ClosureCount
HAVING
    upw.TotalPosts > 0 AND upw.AvgScore >= 2
ORDER BY
    upw.AvgScore DESC, upw.TotalPosts DESC;
