WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN 1 ELSE 0 END) AS TotalPosts,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        AVG(u.Reputation) OVER(PARTITION BY u.Id) AS AvgReputation,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserRanked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank,
        RANK() OVER (ORDER BY TotalBadges DESC) AS BadgeRank
    FROM UserActivity
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(c.UserDisplayName, 'Anonymous') AS LastCommentUser,
        COALESCE(cc.Comment, 'No comments yet') AS LastComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS CommentRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Comments cc ON p.Id = cc.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.LastCommentUser,
        rp.LastComment
    FROM RecentPosts rp
    WHERE rp.CommentRank = 1
)
SELECT
    ur.UserId,
    ur.DisplayName,
    ur.TotalPosts,
    ur.TotalVotes,
    ur.TotalBadges,
    ur.PostRank,
    ur.VoteRank,
    ur.BadgeRank,
    pd.Title AS RecentPostTitle,
    pd.CreationDate AS PostCreationDate,
    pd.ViewCount AS PostViewCount,
    pd.Score AS PostScore,
    pd.LastCommentUser,
    pd.LastComment
FROM UserRanked ur
LEFT JOIN PostDetails pd ON ur.UserId = pd.LastCommentUser
WHERE ur.AvgReputation IS NOT NULL
ORDER BY ur.TotalPosts DESC, ur.TotalVotes DESC, ur.TotalBadges DESC
FETCH FIRST 10 ROWS ONLY
OFFSET 5 ROWS;

