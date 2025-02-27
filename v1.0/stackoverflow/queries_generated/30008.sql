WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 -- Filter for questions
),
UserBadges AS (
    SELECT
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM
        Badges b
    WHERE
        b.Class = 1 -- Counting only gold badges
    GROUP BY
        b.UserId
),
PostHistoryAggregates AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Title edits, body edits, tag edits, suggested edits
    GROUP BY
        ph.PostId
),
RecentComments AS (
    SELECT
        c.PostId,
        COUNT(*) AS CommentCount
    FROM
        Comments c
    WHERE
        c.CreationDate >= NOW() - INTERVAL '30 days' -- Comments in the last 30 days
    GROUP BY
        c.PostId
),
FinalResults AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(ub.BadgeCount, 0) AS GoldBadgeCount,
        COALESCE(pha.EditCount, 0) AS EditCount,
        COALESCE(rc.CommentCount, 0) AS RecentCommentCount,
        CASE 
            WHEN rp.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old'
            ELSE 'New'
        END AS PostAge
    FROM
        RankedPosts rp
    LEFT JOIN
        UserBadges ub ON rp.OwnerDisplayName = ub.UserId
    LEFT JOIN
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    LEFT JOIN
        RecentComments rc ON rp.PostId = rc.PostId
    WHERE
        rp.Rank <= 10
)
SELECT
    PostId,
    Title,
    Score,
    CreationDate,
    OwnerDisplayName,
    GoldBadgeCount,
    EditCount,
    RecentCommentCount,
    PostAge
FROM
    FinalResults
ORDER BY
    Score DESC, 
    GoldBadgeCount DESC, 
    RecentCommentCount DESC;

