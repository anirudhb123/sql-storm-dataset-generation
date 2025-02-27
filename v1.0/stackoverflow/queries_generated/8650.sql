WITH UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.Views,
        p.AnswerCount,
        COALESCE(u.BadgeCount, 0) AS UserBadgeCount
    FROM
        Posts p
    LEFT JOIN UserBadgeCounts u ON p.OwnerUserId = u.UserId
    WHERE
        p.CreationDate >= '2023-01-01'
        AND p.Score > 10
),
CommentCounts AS (
    SELECT
        PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        PostId
),
VoteCounts AS (
    SELECT
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        PostId
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.Views,
    pd.AnswerCount,
    cc.CommentCount,
    vc.UpVotes,
    vc.DownVotes,
    pd.UserBadgeCount
FROM
    PostDetails pd
LEFT JOIN
    CommentCounts cc ON pd.PostId = cc.PostId
LEFT JOIN
    VoteCounts vc ON pd.PostId = vc.PostId
ORDER BY
    pd.Views DESC,
    pd.Score DESC
LIMIT 100;
