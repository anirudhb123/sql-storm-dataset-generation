WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only include questions
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        LastActivityDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        AnswerCount
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore,
        AVG(COALESCE(AnswerCount, 0)) AS AverageAnswerCount
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        TagName
    HAVING 
        COUNT(DISTINCT PostId) > 5 -- Only consider tags with more than 5 posts
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        TotalScore,
        AverageAnswerCount,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    trp.Title,
    trp.OwnerDisplayName,
    tt.TagName,
    tt.TotalViews,
    tt.TotalScore,
    tt.AverageAnswerCount
FROM 
    TopRankedPosts trp
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(SUBSTR(trp.Body, 2, LENGTH(trp.Body) - 2), '><'))
ORDER BY 
    tt.TotalScore DESC, 
    trp.ViewCount DESC;
