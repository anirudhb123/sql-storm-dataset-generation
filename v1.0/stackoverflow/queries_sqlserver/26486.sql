
WITH TagFrequency AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagFrequency
    WHERE 
        PostCount > 1 
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        tt.Tag,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        TopTags tt ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
)
SELECT 
    pd.Tag,
    COUNT(pd.PostId) AS TaggedPostCount,
    AVG(pd.ViewCount) AS AverageViewCount,
    AVG(pd.AnswerCount) AS AverageAnswerCount,
    AVG(pd.Score) AS AverageScore,
    COUNT(DISTINCT u.Id) AS UniqueUsersContributing
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.OwnerUserId = u.Id
GROUP BY 
    pd.Tag
ORDER BY 
    TaggedPostCount DESC, 
    AverageViewCount DESC;
