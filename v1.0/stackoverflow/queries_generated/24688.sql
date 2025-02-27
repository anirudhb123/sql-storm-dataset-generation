WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
),
UserBadgeCounts AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Badges b
    GROUP BY
        b.UserId
),
RecentComments AS (
    SELECT
        c.PostId,
        c.UserId,
        COUNT(*) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM
        Comments c
    GROUP BY
        c.PostId, c.UserId
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        COUNT(DISTINCT rc.PostId) AS TotalRecentComments
    FROM
        Users u
    LEFT JOIN
        UserBadgeCounts b ON u.Id = b.UserId
    LEFT JOIN
        PostVoteSummary vs ON vs.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN
        RecentComments rc ON u.Id = rc.UserId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id, u.DisplayName, b.BadgeCount, vs.UpVotes, vs.DownVotes
)
SELECT
    ua.UserId,
    ua.DisplayName,
    ua.BadgeCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.TotalPosts,
    ua.TotalRecentComments,
    ROW_NUMBER() OVER (ORDER BY ua.TotalUpVotes DESC, ua.BadgeCount DESC) AS Ranking
FROM
    UserActivity ua
WHERE
    ua.TotalPosts > 5
ORDER BY
    ua.TotalUpVotes DESC, ua.TotalPosts DESC;
