
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(a.AnswerCount, 0) AS TotalAnswers,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, a.AnswerCount
),

TopTaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.TotalAnswers,
        rp.CommentCount,
        rp.TagRank,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 
             p.Id,
             SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
             Posts p
         INNER JOIN 
             (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
         WHERE 
             p.PostTypeId = 1) t ON rp.PostId = t.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.OwnerDisplayName, 
        rp.OwnerReputation, rp.TotalAnswers, rp.CommentCount, rp.TagRank
)

SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    OwnerDisplayName,
    OwnerReputation,
    TotalAnswers,
    CommentCount,
    TagRank,
    Tags
FROM 
    TopTaggedPosts
WHERE 
    TagRank <= 5  
ORDER BY 
    CreationDate DESC;
