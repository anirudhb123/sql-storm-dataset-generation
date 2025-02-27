WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        t.TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
        AND ph.CreationDate >= NOW() - INTERVAL '1 month'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    COALESCE(re.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(re.UserDisplayName, 'N/A') AS LastEditedBy,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageScore
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
JOIN 
    TagStatistics ts ON ts.TagName = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.PostRank = 1 -- Only the most recent post for each user
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
