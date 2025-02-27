WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(UNNEST(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '><')), ',')) 
                           ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions from the last year
),
TopRankedTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM t.TagName) AS Tag,
        COUNT(*) AS QuestionCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')::int[])
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TRIM(BOTH '<>' FROM t.TagName)
    HAVING 
        COUNT(*) > 5 -- Only tags with more than 5 questions
),
PopularTagDetails AS (
    SELECT 
        tr.Tag,
        tr.QuestionCount,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount
    FROM 
        TopRankedTags tr
    JOIN 
        RankedPosts rp ON rp.Rank = 1
    WHERE 
        rp.Tags LIKE '%' || tr.Tag || '%'
)
SELECT 
    pt.Tag,
    pt.QuestionCount,
    COUNT(pt.Title) AS TotalPopularQuestions,
    AVG(rp.Score) AS AverageScore,
    AVG(rp.ViewCount) AS AverageViews
FROM 
    PopularTagDetails pt
JOIN 
    RankedPosts rp ON rp.Tags LIKE '%' || pt.Tag || '%'
GROUP BY 
    pt.Tag, pt.QuestionCount
ORDER BY 
    TotalPopularQuestions DESC, AverageScore DESC;
