
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n
         FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
              (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
CommonTags AS (
    SELECT 
        TagName,
        TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagUsage, (SELECT @rank := 0) r
    WHERE 
        TagCount > 1  
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        pu.Location,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users pu ON p.OwnerUserId = pu.Id
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    ct.TagName,
    ct.TagCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.Location
FROM 
    CommonTags ct
JOIN 
    PostDetails pd ON pd.Tags LIKE CONCAT('%', ct.TagName, '%')
ORDER BY 
    ct.Rank, pd.ViewCount DESC;
