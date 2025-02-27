WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation AS AuthorReputation,
        u.DisplayName AS AuthorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
        AND p.CreationDate >= '2020-01-01' -- Only questions created in 2020 and later
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AuthorReputation,
        AuthorDisplayName,
        PostRank,
        CASE 
            WHEN PostRank = 1 THEN 'Latest Question'
            ELSE 'Older Question'
        END AS QuestionStatus
    FROM 
        RankedPosts
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS TotalQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        u.Id, u.DisplayName
),
TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        t.TagName
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AuthorDisplayName,
    ps.AuthorReputation,
    us.TotalViews AS AuthorTotalViews,
    us.TotalScore AS AuthorTotalScore,
    us.TotalQuestions AS AuthorTotalQuestions,
    tu.TagName,
    tu.QuestionCount AS TagQuestionCount,
    tu.TotalViews AS TagTotalViews,
    ps.QuestionStatus
FROM 
    PostStatistics ps
LEFT JOIN 
    UserStatistics us ON ps.AuthorDisplayName = us.DisplayName
LEFT JOIN 
    TagUsage tu ON ps.Title IN (SELECT unnest(string_to_array(ps.Title, ' ')) INTERSECT SELECT TagName FROM Tags)
WHERE 
    ps.QuestionStatus = 'Latest Question'
ORDER BY 
    ps.CreationDate DESC, ps.Score DESC;
