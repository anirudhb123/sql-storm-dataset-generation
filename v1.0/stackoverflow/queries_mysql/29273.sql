
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FrequentTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        u.DisplayName AS ModeratorDisplayName,
        ph.CreationDate AS CloseDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    COUNT(DISTINCT ft.Tag) AS FrequentTagCount,
    COUNT(DISTINCT cp.Id) AS ClosedPostCount,
    GROUP_CONCAT(DISTINCT ft.Tag) AS FrequentTags,
    COUNT(DISTINCT cp.ModeratorDisplayName) AS UniqueModerators
FROM 
    RankedPosts rp
LEFT JOIN 
    FrequentTags ft ON ft.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', numbers.n), '><', -1)
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
GROUP BY 
    rp.OwnerDisplayName, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
HAVING 
    MAX(rp.PostRank) <= 3 
ORDER BY 
    rp.Score DESC, FrequentTagCount DESC;
