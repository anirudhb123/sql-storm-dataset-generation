WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1
),
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT
        ph.UserId,
        COUNT(*) AS EditsCount,
        COUNT(DISTINCT ph.PostId) AS EditedPostsCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6)
    GROUP BY
        ph.UserId
)
SELECT
    us.UserId,
    us.DisplayName,
    us.QuestionsAsked,
    us.AnswersProvided,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    ra.EditsCount,
    ra.EditedPostsCount,
    ra.LastEditDate,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags
FROM
    UserStatistics us
LEFT JOIN
    RecentActivity ra ON us.UserId = ra.UserId 
LEFT JOIN
    RankedPosts rp ON us.UserId = rp.PostId
WHERE
    us.TotalPosts > 10
ORDER BY
    us.Reputation DESC,
    ra.LastEditDate DESC;
