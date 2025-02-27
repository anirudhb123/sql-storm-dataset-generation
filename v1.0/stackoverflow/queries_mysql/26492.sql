
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT @row := @row + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, (SELECT @row := 0) r) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
TagDetails AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        MIN(p.CreationDate) AS FirstUsed,
        MAX(p.CreationDate) AS LastUsed
    FROM 
        PopularTags pt
    JOIN 
        Tags t ON pt.TagName = t.TagName
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CommentCount,
    rp.AnswerCount,
    tt.TagName,
    tt.PostCount,
    tt.FirstUsed,
    tt.LastUsed,
    rp.CreationDate,
    rp.ViewCount
FROM 
    RankedPosts rp
JOIN 
    TagDetails tt ON FIND_IN_SET(tt.TagName, REPLACE(REPLACE(rp.Body, '<', ''), '>', ''))  
WHERE 
    rp.OwnerPostRank <= 5  
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC;
