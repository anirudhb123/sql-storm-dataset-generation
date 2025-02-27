
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.ViewCount, u.DisplayName
),

TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.Author,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 
),

TagsUsage AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS UsageCount
    FROM 
        TopQuestions rp
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
)

SELECT 
    tu.TagName,
    tu.UsageCount,
    COUNT(DISTINCT tq.PostId) AS QuestionCount,
    AVG(tq.ViewCount) AS AvgViews,
    AVG(tq.CommentCount) AS AvgComments
FROM 
    TagsUsage tu
JOIN 
    TopQuestions tq ON tq.Tags LIKE CONCAT('%', tu.TagName, '%')
GROUP BY 
    tu.TagName, tu.UsageCount
ORDER BY 
    tu.UsageCount DESC, QuestionCount DESC;
