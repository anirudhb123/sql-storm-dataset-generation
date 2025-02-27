
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
            Id AS PostId
        FROM Posts
        JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
              UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
        WHERE Tags IS NOT NULL
    ) t ON p.Id = t.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        Tags,
        @view_rank := IF(@prev_views = TotalViews, @view_rank, @row_number) AS ViewsRank,
        @prev_views := TotalViews,
        @row_number := @row_number + 1
    FROM UserPostStats, (SELECT @row_number := 0, @view_rank := 0, @prev_views := NULL) r
    ORDER BY TotalViews DESC
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalScore,
        Tags,
        ViewsRank,
        CASE
            WHEN ViewsRank <= 10 THEN 'Top 10 by Views'
            WHEN Reputation <= 10 THEN 'Top 10 by Reputation'
            ELSE 'Other'
        END AS RankingCategory
    FROM TopUsers
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    Tags,
    RankingCategory
FROM UserRankings
WHERE RankingCategory != 'Other'
ORDER BY TotalViews DESC, Reputation DESC;
