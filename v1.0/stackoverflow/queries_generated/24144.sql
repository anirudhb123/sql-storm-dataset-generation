WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Only Questions
        AND p.Score > 0  -- Only positive scored posts
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY
        u.Id
),
PostDetails AS (
    SELECT
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerDisplayName,
        us.BadgeCount,
        us.LastBadgeDate,
        us.Upvotes,
        us.Downvotes
    FROM
        RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    JOIN UserStats us ON u.Id = us.UserId
    WHERE
        rp.Rank <= 3  -- Get top 3 questions per user
)
SELECT
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.BadgeCount,
    pd.LastBadgeDate,
    pd.Upvotes,
    pd.Downvotes,
    COALESCE(NULLIF(pd.Upvotes, 0), NULL) AS EffectiveUpvotes,
    COALESCE(pd.Downvotes - pd.Upvotes, 0) AS VoteDifference,
    CASE 
        WHEN pd.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges' 
    END AS BadgeStatus
FROM
    PostDetails pd
LEFT JOIN PostHistory ph ON pd.PostId = ph.PostId
WHERE
    ph.PostHistoryTypeId IN (10, 11)  -- Only interested in closed and reopened posts
    AND ph.CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Over the last year
ORDER BY
    pd.ViewCount DESC, 
    pd.Score DESC
LIMIT 50;

