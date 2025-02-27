WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        LATERAL unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS t(TagName)
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasons,
        ph.CreationDate AS ClosedDate,
        RankedPosts.Title,
        RankedPosts.OwnerDisplayName
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON c.Id = CAST(ph.Comment AS INT) -- Assuming Comment stores CloseReasonId here
    JOIN 
        RankedPosts ON ph.PostId = RankedPosts.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened events
    GROUP BY 
        ph.PostId, ph.CreationDate, RankedPosts.Title, RankedPosts.OwnerDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rc.ClosedDate,
    rc.CloseReasons,
    rp.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentClosedPosts rc ON rp.PostId = rc.PostId
WHERE 
    rp.Rank <= 5 -- Get top 5 recent questions per tag
ORDER BY 
    rp.Tags, rp.CreationDate DESC;
