
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        Author,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount,
        AVG(Score) AS AvgScore
    FROM 
        FilteredPosts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    f.Author,
    f.Title,
    f.CreationDate,
    t.Tag,
    t.PostCount,
    t.AvgScore,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers
FROM 
    FilteredPosts f
JOIN 
    TagStats t ON f.Tags LIKE CONCAT('%', t.Tag, '%')
JOIN 
    UserStats u ON f.Author = u.DisplayName
ORDER BY 
    t.Tag, f.CreationDate DESC;
