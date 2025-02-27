WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
NorminalTagCount AS (
    SELECT 
        SUBSTRING(tags.TagName FROM 2 FOR LENGTH(tags.TagName) - 2) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tags(TagName) ON true
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        tags.TagName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(ph.Comment, '; ') AS Comments
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    ntc.TagName,
    ntc.TagCount,
    phs.EditCount,
    phs.Comments
FROM 
    RankedPosts rp
LEFT JOIN 
    NorminalTagCount ntc ON ntc.TagName = ANY(STRING_TO_ARRAY(rp.Title, ' ')) -- Modify as needed to suit 'Tags'
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC;
