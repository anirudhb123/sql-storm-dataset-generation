WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 6 THEN 'Edited Tags' END, ', ') AS TagEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedMetrics AS (
    SELECT 
        u.DisplayName,
        up.UpVotes,
        up.DownVotes,
        pm.PostId,
        COALESCE(pm.EditCount, 0) AS EditCount,
        pm.FirstEditDate,
        pm.LastEditDate,
        pm.TagEdits,
        rp.RecentPostRank,
        rp.Title AS RecentPostTitle
    FROM 
        UserMetrics up
    JOIN 
        Users u ON up.UserId = u.Id
    LEFT JOIN 
        PostHistorySummary pm ON pm.PostId = ANY(ARRAY(SELECT PostId FROM RecentPosts WHERE OwnerUserId = u.Id))
    LEFT JOIN 
        RecentPosts rp ON rp.PostId = pm.PostId
)
SELECT 
    *,
    CASE 
        WHEN EditCount > 0 THEN 'Edited Posts: ' || EditCount
        ELSE 'No Edits'
    END AS EditStatus,
    CASE 
        WHEN RecentPostRank IS NOT NULL AND RecentPostRank = 1 THEN 'Most Recent'
        WHEN RecentPostRank IS NULL THEN 'No Recent Posts'
        ELSE 'Other Recent Post'
    END AS RecentPostStatus
FROM 
    CombinedMetrics
WHERE 
    (UPPER(DisplayName) LIKE '%SQL%' OR LOWER(TagEdits) LIKE '%tags%')
ORDER BY 
    UpVotes DESC, EditCount DESC NULLS LAST
LIMIT 100;
