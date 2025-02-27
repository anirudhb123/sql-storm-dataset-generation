WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.Status IS NULL -- Exclude deleted posts
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagCounts AS (
    SELECT 
        TagName, 
        COUNT(*) AS Count
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        Count DESC
    LIMIT 10
),
TopAnswerStatistics AS (
    SELECT 
        p.Id AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.Owner,
    rp.CreationDate,
    tc.TagName,
    tc.Count AS TagUsageCount,
    tas.AnswerCount,
    tas.AverageScore
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON rp.Tags ILIKE '%' || tc.TagName || '%' -- Match any tags
LEFT JOIN 
    TopAnswerStatistics tas ON rp.PostId = tas.QuestionId
WHERE 
    rp.Rank <= 5 -- Top 5 most recent questions
ORDER BY 
    rp.CreationDate DESC, tc.Count DESC;
