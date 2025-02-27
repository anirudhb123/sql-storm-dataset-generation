WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),

TagStatistics AS (
    SELECT 
        t.Id,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViewCount,
        AVG(COALESCE(u.Reputation, 0)) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        t.IsRequired IS NULL OR t.IsModeratorOnly IS NULL
    GROUP BY 
        t.Id, t.TagName
),

PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Title/Body/Tags edits
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.TagsArray,
    ts.PostCount AS TagPostCount,
    ts.TotalViewCount AS TagTotalViewCount,
    ts.AvgUserReputation AS TagAvgUserReputation,
    pha.EditCount,
    pha.UniqueEditors
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStatistics ts ON rp.TagsArray @> ARRAY[ts.TagName]  -- Check if tag belongs to the post
LEFT JOIN 
    PostHistoryAnalytics pha ON rp.PostId = pha.PostId
WHERE 
    rp.ViewRank <= 5  -- Select top 5 viewed posts for each user
ORDER BY 
    rp.CreationDate DESC;
