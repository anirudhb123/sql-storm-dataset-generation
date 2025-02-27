
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts f
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
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
    FilteredPosts f ON f.Tags LIKE CONCAT('%', t.Tag, '%')
WHERE 
    t.TagRank <= 5  
ORDER BY 
    t.PostCount DESC, 
    f.PostCreationDate DESC;
