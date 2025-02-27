WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(UPPER(SUBSTRING(p.Body FROM '([A-Za-z]+)')),'No Text') AS FirstWord,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1 -- Only count tags from questions
    GROUP BY 
        t.Id, t.TagName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.Title,
    rp.FirstWord,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rc.TagId,
    rc.TagName,
    rc.PostCount,
    cp.CloseCount
FROM 
    RankedPosts rp
JOIN 
    TagCounts rc ON rp.PostId = rc.TagId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank = 1 -- Select the most recent question from each user
ORDER BY 
    rp.CreationDate DESC;
