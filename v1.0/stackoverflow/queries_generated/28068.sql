WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY array_length(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'), 1) ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rr.rank,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts ah ON rp.PostId = ah.AcceptedAnswerId
    WHERE 
        rp.Rank <= 10 -- Get top 10 by score
),
TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '>')) AS Tag,
        COUNT(*) AS Count
    FROM 
        FilteredPosts
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        Count
    FROM 
        TagCounts
    ORDER BY 
        Count DESC
    LIMIT 5 -- Get top 5 tags
)
SELECT 
    fp.Title,
    fp.Score,
    fp.CreationDate,
    fp.OwnerDisplayName,
    tt.Tag,
    tt.Count
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.Tag = ANY(string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '>'))
ORDER BY 
    fp.Score DESC, 
    tt.Count DESC;
