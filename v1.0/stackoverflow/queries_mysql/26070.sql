
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1  
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentsCount,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) TagName
        FROM 
            Posts
        INNER JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
        WHERE 
            PostTypeId = 1 
    ) AS TagsUnnested
    GROUP BY 
        TagName
),
CombinedStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        pa.CommentsCount,
        pa.HistoryCount,
        ts.TagName,
        ts.TagCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
    LEFT JOIN 
        TagStats ts ON FIND_IN_SET(ts.TagName, SUBSTRING(REPLACE(SUBSTRING(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><', ','), 1, LENGTH(rp.Tags) - 2)) > 0
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CreationDate,
    ViewCount,
    CommentsCount,
    HistoryCount,
    OwnerDisplayName,
    GROUP_CONCAT(DISTINCT CONCAT(TagName, ' (Count: ', TagCount, ' )') ORDER BY TagName ASC SEPARATOR ', ') AS TagSummary
FROM 
    CombinedStats
GROUP BY 
    PostId, Title, Body, Tags, CreationDate, ViewCount, CommentsCount, HistoryCount, OwnerDisplayName
ORDER BY 
    ViewCount DESC
LIMIT 10;
