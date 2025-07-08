
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ph.CreationDate AS PostCreationDate,
        ph.RevisionGUID,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY ph.CreationDate DESC) AS LatestRevision
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.LatestRevision = 1  
),
TagCounts AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts,
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) t
    GROUP BY 
        TRIM(value)
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1  
)
SELECT 
    t.Tag,
    t.PostCount,
    f.Title,
    f.OwnerDisplayName,
    f.PostCreationDate,
    f.RevisionGUID
FROM 
    TopTags t
JOIN 
    FilteredPosts f ON f.Tags LIKE '%' || t.Tag || '%' 
WHERE 
    t.TagRank <= 5  
ORDER BY 
    t.PostCount DESC, 
    f.PostCreationDate DESC;
