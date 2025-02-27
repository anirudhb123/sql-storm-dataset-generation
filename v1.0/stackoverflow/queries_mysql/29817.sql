
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredTags AS (
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
          (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n1,
          (SELECT @row := 0) n2) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        RN = 1 
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        FilteredTags
    GROUP BY 
        Tag
),
MostPopularTags AS (
    SELECT 
        Tag,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        TagCount > 0
)
SELECT 
    pt.Name AS PostType, 
    mpt.Tag, 
    mpt.TagCount, 
    COUNT(DISTINCT p.id) * (CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS CountAcceptedAnswers, 
    COUNT(DISTINCT c.id) AS CommentCount
FROM 
    MostPopularTags mpt 
JOIN 
    Posts p ON p.Tags LIKE CONCAT('%', mpt.Tag, '%') 
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON c.PostId = p.Id
GROUP BY 
    pt.Name, mpt.Tag, mpt.TagCount
ORDER BY 
    mpt.TagCount DESC, pt.Name;
