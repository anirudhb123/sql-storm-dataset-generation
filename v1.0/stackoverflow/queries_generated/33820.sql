WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 AND  -- Filter for questions
        p.Score > 0  -- Only consider questions with a positive score
), 
UserStatistics AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.Reputation
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)
SELECT
    up.UserId,
    us.Reputation,
    us.BadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS QuestionCreationDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViewCount,
    phs.EditCount,
    phs.LastEditDate,
    phs.HistoryTypes
FROM
    RankedPosts rp
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE
    rp.Rank = 1  -- Only get the top-ranked question for each user
ORDER BY
    us.Reputation DESC,  -- Order primarily by user reputation 
    rp.Score DESC; -- Then by question score
