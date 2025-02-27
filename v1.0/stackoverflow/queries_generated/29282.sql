WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ug.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(p.Tags, ',')::int[])
    LEFT JOIN 
        Users ug ON p.OwnerUserId = ug.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- within the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, ug.Reputation
),
PopularUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(ViewCount) AS TotalViews,
        AVG(OwnerReputation) AS AvgReputation
    FROM 
        RankedPosts
    GROUP BY 
        OwnerDisplayName
    HAVING 
        COUNT(PostId) > 5 -- users with more than 5 posts
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS UsageCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(p.Tags, ',')::int[])
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10 -- Top 10 tags
),
RecentCloseReasons AS (
    SELECT 
        p.Id AS PostId, 
        ph.Comment AS CloseReason, 
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate > NOW() - INTERVAL '30 days' -- within the last 30 days
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    pu.OwnerDisplayName,
    pu.TotalViews,
    pu.AvgReputation,
    tt.TagName AS TopTag,
    rcr.CloseReason,
    rcr.CloseDate
FROM 
    RankedPosts rp
JOIN 
    PopularUsers pu ON rp.OwnerDisplayName = pu.OwnerDisplayName
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY (STRING_TO_ARRAY(rp.Tags, ','))
LEFT JOIN 
    RecentCloseReasons rcr ON rcr.PostId = rp.PostId
WHERE 
    rp.PostRank = 1 -- top post for each user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
