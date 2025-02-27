
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        ph.CreationDate AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (1, 2, 4)
    WHERE 
        p.PostTypeId = 1 
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS TagFrequency
    FROM 
        Posts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.OwnerReputation,
    rp.PostCreationDate,
    tc.Tag,
    tc.TagFrequency,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON rp.Tags LIKE CONCAT('%', tc.Tag, '%')
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.OwnerReputation DESC, 
    CloseCount DESC, 
    rp.PostCreationDate DESC;
