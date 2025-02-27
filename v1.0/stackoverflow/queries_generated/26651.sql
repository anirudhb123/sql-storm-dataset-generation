WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Consider only Questions
),

StringProcessedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        ARRAY_LENGTH(string_to_array(rp.Tags, '>'), 1) AS TagCount,
        REPLACE(REPLACE(rp.Body, '<p>', ''), '</p>', '') AS ProcessedBody -- Strip HTML paragraph tags for analysis
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Only take top 10 posts by view count per tag
),

HistoricalEdits AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.CreationDate, ': ', ph.Comment), ' | ' ORDER BY ph.CreationDate) AS EditHistory
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) -- Edit Title and Body, Suggested Edit Applied
    GROUP BY 
        ph.PostId
)

SELECT 
    spp.PostId,
    spp.Title,
    spp.OwnerDisplayName,
    spp.CreationDate,
    spp.ViewCount,
    spp.TagCount,
    spp.ProcessedBody,
    he.EditHistory
FROM 
    StringProcessedPosts spp
LEFT JOIN 
    HistoricalEdits he ON spp.PostId = he.PostId
ORDER BY 
    spp.ViewCount DESC;
