WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(pa.PostCount, 0) AS PostCount,
        COALESCE(pa.TotalViews, 0) AS TotalViews,
        COALESCE(pa.AvgScore, 0) AS AvgScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.AvgScore,
    ups.BadgeCount,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'PostId', pd.PostId,
            'Title', pd.Title,
            'CreationDate', pd.CreationDate,
            'CommentCount', pd.CommentCount,
            'AnswerCount', pd.AnswerCount,
            'HasAcceptedAnswer', pd.HasAcceptedAnswer
        )
    ) AS Posts
FROM UserPostStats ups
JOIN PostDetails pd ON ups.UserId = pd.OwnerUserId
WHERE ups.PostCount > 0 
AND ups.BadgeCount > 0
GROUP BY ups.UserId, ups.DisplayName, ups.PostCount, ups.TotalViews, ups.AvgScore, ups.BadgeCount
ORDER BY ups.BadgeCount DESC, ups.TotalViews DESC, ups.PostCount DESC
LIMIT 10;

-- Additionally, compute aggregate statistics for edge cases
SELECT 
    AVG(ups.PostCount) AS AvgPostCount,
    MIN(ups.PostCount) AS MinPostCount,
    MAX(ups.PostCount) AS MaxPostCount,
    SUM(CASE WHEN ups.PostCount = 0 THEN 1 ELSE 0 END) AS UsersWithNoPosts
FROM UserPostStats ups;
