
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
            value AS TagName
        FROM 
            Posts
        CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
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
        TagStats ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
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
    STRING_AGG(DISTINCT TagName + ' (Count: ' + CAST(TagCount AS VARCHAR) + ' )', ', ') AS TagSummary
FROM 
    CombinedStats
GROUP BY 
    PostId, Title, Body, Tags, CreationDate, ViewCount, CommentsCount, HistoryCount, OwnerDisplayName
ORDER BY 
    ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
