
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.OwnerReputation,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  
),

TagStatistics AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(substring(p.Tags, 2, LEN(p.Tags)-2), '><')) AS tag  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        tag.TagName
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.ViewCount,
    fp.Score,
    ts.TagName,
    ts.PostCount,
    ts.AverageViewCount,
    ts.AverageScore
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagStatistics ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(substring(fp.Tags, 2, LEN(fp.Tags)-2), '><'))
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC;
