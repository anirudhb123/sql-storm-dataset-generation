
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC, p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 /* Questions */
        AND p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) /* Last year */
),

TopPostOwners AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(CommentCount) AS TotalComments
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 5 /* Top 5 posts per user */
    GROUP BY 
        OwnerDisplayName
),

TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1)) AS Tag,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 /* Questions */
        AND Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)

SELECT 
    o.OwnerDisplayName,
    o.PostCount,
    o.TotalScore,
    o.TotalViews,
    o.TotalAnswers,
    o.TotalComments,
    t.Tag,
    t.UsageCount
FROM 
    TopPostOwners o
JOIN 
    TopTags t ON o.PostCount > 5 /* Arbitrary filter for engagement */
ORDER BY 
    o.TotalScore DESC, o.OwnerDisplayName, t.UsageCount DESC;
