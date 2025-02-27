WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(ph.Comment, 'No Comments') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.LastEditComment
FROM UserActivity ua
LEFT JOIN UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN PostDetails pd ON ua.UserId = pd.PostId
WHERE ua.TotalPosts > 10
  AND (ua.TotalUpVotes - ua.TotalDownVotes) > 5
  AND pd.rn = 1
ORDER BY ua.TotalPosts DESC, ua.TotalUpVotes DESC
LIMIT 100;
