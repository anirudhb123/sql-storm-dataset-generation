
WITH TagFrequency AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @row_number := @row_number + 1 AS Rank
    FROM 
        TagFrequency, (SELECT @row_number := 0) AS r
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
        TopTags tt ON FIND_IN_SET(tt.Tag, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1))
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
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
