WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
RelevantTags AS (
    SELECT 
        TAG.tag AS Tag,
        COUNT(DISTINCT rp.PostId) AS PostCount
    FROM 
        (SELECT DISTINCT UNNEST(STRING_TO_ARRAY(Tags, '><')) as tag FROM Posts) TAG
    GROUP BY 
        TAG.tag
    HAVING 
        COUNT(DISTINCT rp.PostId) > 10 -- Tags that are used in more than 10 questions
),
PostStatistics AS (
    SELECT 
        rp.OwnerDisplayName,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rt.Tag,
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        RelevantTags rt ON rt.Tag = ANY(UNNEST(STRING_TO_ARRAY(rp.Tags, '><')))
    WHERE 
        rp.PostRank <= 3 -- Top 3 questions per user based on score
),
FinalStats AS (
    SELECT 
        OwnerDisplayName,
        COUNT(*) AS TopQuestionCount,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        AVG(OwnerReputation) AS AvgReputation
    FROM 
        PostStatistics
    GROUP BY 
        OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    TopQuestionCount,
    TotalViews,
    TotalAnswers,
    AvgReputation
FROM 
    FinalStats
ORDER BY 
    TotalViews DESC, 
    TopQuestionCount DESC;
