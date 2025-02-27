
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        @row_num := IF(@current_user_id = p.OwnerUserId, @row_num + 1, 1) AS UserPostRank,
        @current_user_id := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag 
         ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    CROSS JOIN (SELECT @row_num := 0, @current_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.Score
),
UserPostStats AS (
    SELECT 
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.AnswerCount) AS TotalAnswers,
        COUNT(p.Id) AS TotalPosts,
        MAX(p.CreationDate) AS LatestPostDate,
        MAX(p.Score) AS HighestScore,
        GROUP_CONCAT(DISTINCT t.TagName) AS AssociatedTags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS tag
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) AS tag 
         ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        u.DisplayName
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        ps.TotalViews,
        ps.TotalAnswers,
        ps.TotalPosts,
        ps.LatestPostDate,
        ps.HighestScore,
        ps.AssociatedTags,
        @view_rank := @view_rank + 1 AS ViewRank,
        @answer_rank := @answer_rank + 1 AS AnswerRank
    FROM 
        Users u
    JOIN 
        UserPostStats ps ON u.DisplayName = ps.DisplayName
    CROSS JOIN (SELECT @view_rank := 0, @answer_rank := 0) AS vars
    ORDER BY ps.TotalViews DESC, ps.TotalAnswers DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalViews,
    tu.TotalAnswers,
    tu.TotalPosts,
    tu.LatestPostDate,
    tu.HighestScore,
    tu.AssociatedTags,
    CASE 
        WHEN tu.ViewRank <= 10 THEN 'Top View Users' 
        WHEN tu.AnswerRank <= 10 THEN 'Top Answer Users' 
        ELSE 'Others' 
    END AS UserCategory
FROM 
    TopUsers tu
WHERE 
    tu.Reputation > 1000
ORDER BY 
    tu.TotalViews DESC, 
    tu.TotalAnswers DESC;
