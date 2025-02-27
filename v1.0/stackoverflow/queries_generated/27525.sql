WITH TagFrequency AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        Tag
), 
PopularTags AS (
    SELECT 
        Tag,
        Frequency,
        RANK() OVER (ORDER BY Frequency DESC) AS TagRank
    FROM 
        TagFrequency
    WHERE 
        Frequency > 5 -- Only consider tags with more than 5 occurrences
), 
QuestionDetails AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        pt.Name AS PostType,
        COALESCE( pf.Frequency, 0 ) AS Popularity
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PopularTags pf ON pf.Tag = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) 
    WHERE 
        p.PostTypeId = 1 -- Question
    ORDER BY 
        p.CreationDate DESC
)
SELECT 
    qd.QuestionId,
    qd.Title,
    qd.CreationDate,
    qd.Owner,
    qd.PostType,
    p.Tag,
    p.Frequency AS PopularTagFrequency
FROM 
    QuestionDetails qd
LEFT JOIN 
    PopularTags p ON p.TagRank <= 10 -- Get top 10 popular tags
ORDER BY 
    qd.CreationDate DESC, 
    p.Frequency DESC;
