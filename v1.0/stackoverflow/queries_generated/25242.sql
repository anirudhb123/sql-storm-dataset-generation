WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- only questions
),
TagAggregates AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- only questions
    GROUP BY 
        Tag
),
CloseReasonAnalysis AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(ct.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON ph.Comment::int = ct.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- only counting close and reopen events
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    tg.PostCount,
    tg.AvgScore,
    cra.CloseCount,
    cra.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    TagAggregates tg ON rp.Tags LIKE '%' || tg.Tag || '%'
LEFT JOIN 
    CloseReasonAnalysis cra ON rp.PostId = cra.PostId
WHERE 
    rp.TagRank <= 5 -- limit to top 5 posts per tag
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
