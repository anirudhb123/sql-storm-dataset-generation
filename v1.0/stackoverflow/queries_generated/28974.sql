WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Only considering Questions
),
MaxViews AS (
    SELECT
        Tags,
        MAX(ViewCount) AS MaxViewCount
    FROM
        RankedPosts
    GROUP BY
        Tags
),
PopularTags AS (
    SELECT
        rp.Tags,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount
    FROM
        RankedPosts rp
    JOIN
        MaxViews mv ON rp.Tags = mv.Tags AND rp.ViewCount = mv.MaxViewCount
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Votes v ON u.Id = v.UserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    WHERE
        u.Reputation > 1000  -- Only engaging users with higher reputation
    GROUP BY
        u.Id, u.DisplayName
),
EngagementDetails AS (
    SELECT
        ut.DisplayName,
        pt.Tags,
        pt.Title,
        pt.ViewCount,
        ut.VoteCount,
        ut.Upvotes,
        ut.Downvotes,
        ut.BadgeCount
    FROM
        UserEngagement ut
    JOIN
        PopularTags pt ON pt.Tags IN (
            SELECT DISTINCT Tags FROM PopularTags
        )
)
SELECT
    ed.DisplayName,
    ed.Tags,
    ed.Title,
    ed.ViewCount,
    ed.VoteCount,
    ed.Upvotes,
    ed.Downvotes,
    ed.BadgeCount
FROM
    EngagementDetails ed
ORDER BY
    ed.ViewCount DESC, ed.BadgeCount DESC;
