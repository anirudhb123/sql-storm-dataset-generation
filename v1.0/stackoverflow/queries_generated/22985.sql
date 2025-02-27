WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS t(TagName) ON true
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.Comment AS CloseReason,
        COUNT(p.Id) OVER (PARTITION BY p.Id) AS CloseCount
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    ub.BadgeCount,
    pchi.EditCount,
    cp.CloseReason,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive Feedback'
        ELSE 'Needs Improvement'
    END AS FeedbackStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryCounts pchi ON rp.PostId = pchi.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.Id
WHERE 
    rp.rn = 1  -- Only latest post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;

This query employs multiple SQL features including CTEs, window functions, aggregations, outer joins, and complex predicates, yielding a rich selection of data representing users and their latest posts, while evaluating their feedback status and badge counts.
