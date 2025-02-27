WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(b.Class) AS TotalBadgeClass,
        AVG(DATEDIFF(second, p.CreationDate, p.LastActivityDate)) AS AvgPostActivityDuration
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE p.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY p.Id
),
EngagementMetrics AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.AnswerCount,
        pd.CommentCount,
        pd.VoteCount,
        ua.TotalScore AS UserTotalScore,
        ua.TotalCommentScore AS UserTotalCommentScore,
        ua.TotalBadgeClass AS UserTotalBadgeClass,
        ua.AvgPostActivityDuration AS UserAvgPostActivityDuration
    FROM UserActivity ua
    JOIN PostDetails pd ON ua.UserId = pd.PostId
)
SELECT 
    em.DisplayName,
    em.Title,
    em.CreationDate,
    em.ViewCount,
    em.AnswerCount,
    em.CommentCount,
    em.VoteCount,
    em.UserTotalScore,
    em.UserTotalCommentScore,
    em.UserTotalBadgeClass,
    em.UserAvgPostActivityDuration
FROM EngagementMetrics em
ORDER BY em.UserTotalScore DESC, em.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
