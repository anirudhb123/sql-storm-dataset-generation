WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
AggregatedTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        Tag
),
MostActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.AnswerCount) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Score,
    rp.Author,
    at.PostCount AS TagUsage,
    mau.DisplayName AS ActiveUser,
    mau.QuestionCount,
    mau.TotalAnswers
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedTags at ON rp.Tags LIKE '%' || at.Tag || '%'
LEFT JOIN 
    MostActiveUsers mau ON rp.Author = mau.DisplayName
WHERE 
    rp.rn = 1 -- Get latest post per tag
ORDER BY 
    rp.CreationDate DESC;
