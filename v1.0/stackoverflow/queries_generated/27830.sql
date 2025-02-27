WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ts.TagsArray,
        ROW_NUMBER() OVER (PARTITION BY ARRAY_LENGTH(ts.TagsArray, 1) ORDER BY p.ViewCount DESC) as Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        (SELECT 
            p.Id,
            string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS TagsArray
        FROM 
            Posts p WHERE p.PostTypeId = 1) ts
        ON p.Id = ts.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
AggregatedPostData AS (
    SELECT 
        rp.TagsArray[1] AS MainTag,
        AVG(rp.ViewCount) AS AvgViewCount,
        SUM(rp.AnswerCount) AS TotalAnswers,
        SUM(rp.CommentCount) AS TotalComments,
        COUNT(*) AS PostCount
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.TagsArray[1]
),
TagPopularity AS (
    SELECT 
        tg.TagName,
        COUNT(*) AS TagPostCount,
        SUM(COALESCE(bp.PostCount, 0)) AS TagPostAggregates
    FROM 
        Tags tg
    LEFT JOIN 
        AggregatedPostData bp ON tg.TagName = bp.MainTag
    GROUP BY 
        tg.TagName
),
FinalResults AS (
    SELECT 
        tp.TagName,
        tp.TagPostCount,
        tp.TagPostAggregates,
        COALESCE(tp.TagPostAggregates / NULLIF(tp.TagPostCount, 0), 0) AS AvgPostAggregates
    FROM 
        TagPopularity tp
)
SELECT 
    fr.TagName,
    fr.TagPostCount,
    fr.TagPostAggregates,
    fr.AvgPostAggregates
FROM 
    FinalResults fr
WHERE 
    fr.TagPostCount > 5 
ORDER BY 
    fr.TagPostAggregates DESC;
