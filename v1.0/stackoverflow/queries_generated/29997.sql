WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 YEAR' -- Posts from the last year
),
TagAnalysis AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>'))::int)
                           WHERE p.PostTypeId = 1)
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5 -- At least 5 posts per tag
),
CloseReasonStats AS (
    SELECT 
        ch.Comment AS CloseReason, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.PostHistoryTypeId = 10 AND ph.Comment = crt.Id::varchar
    GROUP BY 
        ch.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ta.TagName,
    ta.PostCount AS TagPostCount,
    ta.TotalViews AS TagTotalViews,
    crs.CloseReason,
    crs.CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAnalysis ta ON rp.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ta.TagName || '%')
LEFT JOIN 
    CloseReasonStats crs ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5 -- Top 5 posts per user
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
