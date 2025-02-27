WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, p.ViewCount, p.Score
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ActivityCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days' -- Last 30 days
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Owner,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        COALESCE(SUM(pa.ActivityCount), 0) AS RecentActivityCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
    WHERE 
        rp.PostRank = 1 -- Taking the most recent post per user
    GROUP BY 
        rp.PostId, rp.Title, rp.Owner, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.Owner,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.Tags,
    pm.RecentActivityCount,
    CASE 
        WHEN pm.RecentActivityCount > 5 THEN 'Highly Active'
        WHEN pm.RecentActivityCount BETWEEN 1 AND 5 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityStatus
FROM 
    PostMetrics pm
ORDER BY 
    pm.Score DESC, pm.CreationDate DESC
LIMIT 10;
