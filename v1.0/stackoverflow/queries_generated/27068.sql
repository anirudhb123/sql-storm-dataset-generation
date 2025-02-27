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
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Within the last year
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(Tags, '<>')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
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
        TagCount > 5 -- Only tags used in more than 5 questions
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
        PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, '<>'))
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
LIMIT 10; -- Top 10 users with the most questions in the past year
