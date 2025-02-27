WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
),
QuestionStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(*) AS TotalQuestions,
        AVG(rp.Score) AS AverageScore,
        SUM(rp.CommentCount) AS TotalComments,
        MAX(rp.CreationDate) AS MostRecentQuestion
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5  -- Limit to the latest 5 posts per user
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    qs.OwnerDisplayName,
    qs.TotalQuestions,
    qs.AverageScore,
    qs.TotalComments,
    TO_CHAR(qs.MostRecentQuestion, 'YYYY-MM-DD') AS MostRecentQuestionDate,
    STUFF((SELECT ', ' + t.TagName
           FROM Tags t
           INNER JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
           WHERE p.OwnerUserId IN (SELECT Id FROM Users WHERE DisplayName = qs.OwnerDisplayName)
           FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS AssociatedTags
FROM 
    QuestionStats qs
ORDER BY 
    qs.TotalQuestions DESC, 
    qs.AverageScore DESC;
