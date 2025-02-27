
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.Body,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > DATEADD(year, -1, '2024-10-01')
),
TagStatistics AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, '<>') 
    GROUP BY 
        value
),
PopularTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 5 
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        pt.TagName,
        pt.TagRank
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '<>'))
)
SELECT 
    pd.OwnerDisplayName,
    COUNT(pd.PostId) AS QuestionCount,
    SUM(pd.ViewCount) AS TotalViews,
    AVG(pd.Score) AS AverageScore,
    SUM(pd.AnswerCount) AS TotalAnswers,
    STRING_AGG(DISTINCT pd.TagName, ', ') AS Tags,
    STRING_AGG(DISTINCT CONCAT('Rank: ', pd.TagRank, ' Tag: ', pd.TagName), '; ') AS TagRanks
FROM 
    PostDetails pd
GROUP BY 
    pd.OwnerDisplayName
ORDER BY 
    QuestionCount DESC, TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
