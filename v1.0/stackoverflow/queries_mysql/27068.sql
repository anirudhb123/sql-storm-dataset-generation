
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
        AND p.CreationDate > DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    JOIN 
        (SELECT n FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers) AS numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1
    GROUP BY 
        TagName
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
        PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Tags)
)
SELECT 
    pd.OwnerDisplayName,
    COUNT(pd.PostId) AS QuestionCount,
    SUM(pd.ViewCount) AS TotalViews,
    AVG(pd.Score) AS AverageScore,
    SUM(pd.AnswerCount) AS TotalAnswers,
    GROUP_CONCAT(DISTINCT pd.TagName ORDER BY pd.TagName SEPARATOR ', ') AS Tags,
    GROUP_CONCAT(DISTINCT CONCAT('Rank: ', pd.TagRank, ' Tag: ', pd.TagName) ORDER BY pd.TagRank SEPARATOR '; ') AS TagRanks
FROM 
    PostDetails pd
GROUP BY 
    pd.OwnerDisplayName
ORDER BY 
    QuestionCount DESC, TotalViews DESC
LIMIT 10;
