WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
ExtendedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment,
        COALESCE(c.CloseReasonId, 0) AS CloseReasonId
    FROM 
        PostHistory ph
    LEFT JOIN CloseReasonTypes c ON ph.PostHistoryTypeId = 10 -- Assuming we're interested in close events
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    MAX(eph.HistoryCreationDate) AS LastHistoryEvent,
    MAX(CASE WHEN eph.PostHistoryTypeId = 10 THEN eph.Comment END) AS LastCloseReason,
    SUM(CASE WHEN eph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) OVER (PARTITION BY rp.PostId) AS DeleteCount,
    COALESCE(NULLIF(SUBSTRING(rp.Title FROM '\[(.*?)\]'), ''), 'No Tag') AS ExtractedTag,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
    COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN ExtendedPostHistory eph ON rp.PostId = eph.PostId
LEFT JOIN Votes v ON rp.PostId = v.PostId
WHERE 
    ub.BadgeCount > 0 
    AND (rp.RecentRank <= 3 OR eph.PostHistoryTypeId IS NOT NULL) -- Recent or has history
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, u.DisplayName, ub.BadgeCount
ORDER BY 
    LastHistoryEvent DESC NULLS LAST, 
    UpVoteCount DESC, 
    DeleteCount;
