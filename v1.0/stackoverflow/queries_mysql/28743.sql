
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        Tags,
        OwnerName,
        CreationDate,
        LastActivityDate
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1 
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TopPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
MostCommonTag AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    t.TagName,
    t.TagCount,
    COUNT(tp.PostId) AS PostFrequency,
    AVG(u.Reputation) AS AverageUserReputation,
    MAX(tp.CreationDate) AS LastPostDate
FROM 
    MostCommonTag t
JOIN 
    TopPosts tp ON tp.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN 
    Users u ON tp.OwnerName = u.DisplayName
WHERE 
    t.TagRank <= 5 
GROUP BY 
    t.TagName, t.TagCount
ORDER BY 
    t.TagCount DESC;
