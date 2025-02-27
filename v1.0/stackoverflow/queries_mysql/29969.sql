
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER(PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(value, 2, CHAR_LENGTH(value) - 2)) AS TagName
    FROM 
        RankedPosts
    CROSS JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS value
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1) AS values
    GROUP BY 
        TRIM(SUBSTRING(value, 2, CHAR_LENGTH(value) - 2))
),
PostsWithMostAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(a.Id) AS TotalAnswers
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    pt.TagName,
    COUNT(DISTINCT rp.PostId) AS QuestionCount,
    COALESCE(SUM(pma.TotalAnswers), 0) AS TotalAnswers,
    AVG(rp.ViewCount) AS AvgViewCount,
    AVG(TIMESTAMPDIFF(MINUTE, rp.CreationDate, NOW())) AS AvgTimeSinceCreation
FROM 
    PopularTags pt
JOIN 
    RankedPosts rp ON FIND_IN_SET(pt.TagName, rp.Tags) 
LEFT JOIN 
    PostsWithMostAnswers pma ON rp.PostId = pma.PostId
WHERE 
    rp.TagRank <= 5 
GROUP BY 
    pt.TagName, rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.ViewCount, rp.AnswerCount, rp.OwnerDisplayName, rp.TagRank
ORDER BY 
    QuestionCount DESC, TotalAnswers DESC;
