WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.Tags,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
MostActiveUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS QuestionCount,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5 -- At least 5 questions
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        tag.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS JOIN LATERAL
        UNNEST(string_to_array(p.Tags, '><')) AS tag -- Split tags using '><'
    GROUP BY 
        p.Id, tag.TagName
),
PopularTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalTagCount
    FROM 
        PostTags
    GROUP BY 
        TagName
    ORDER BY 
        TotalTagCount DESC
    LIMIT 10
)
SELECT 
    R.PostId,
    R.OwnerName,
    R.Title,
    R.Body,
    R.CreationDate,
    R.Tags,
    M.QuestionCount,
    M.TotalAnswers,
    M.TotalViews,
    P.TagName,
    P.TotalTagCount
FROM 
    RankedPosts R
JOIN 
    MostActiveUsers M ON R.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = M.OwnerUserId)
JOIN 
    PopularTags P ON R.Tags ILIKE '%' || P.TagName || '%'
WHERE 
    R.Rank = 1 -- Most recent question per user
ORDER BY 
    R.CreationDate DESC, 
    M.TotalAnswers DESC;
