
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts p
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
), TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS TagFrequency,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        ProcessedTags
    JOIN 
        Posts p ON ProcessedTags.PostId = p.Id
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagFrequency,
        TotalViews,
        TotalScore,
        @row_number := @row_number + 1 AS Rank
    FROM 
        TagStatistics, (SELECT @row_number := 0) r 
    ORDER BY 
        TagFrequency DESC, TotalViews DESC
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        CommentCount,
        UpVotes,
        DownVotes,
        @user_row_number := @user_row_number + 1 AS UserRank
    FROM 
        UserActivity, (SELECT @user_row_number := 0) r 
)
SELECT 
    t.TagName,
    t.TagFrequency,
    t.TotalViews,
    t.TotalScore,
    u.DisplayName AS TopUser,
    u.QuestionCount,
    u.CommentCount,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes
FROM 
    TopTags t
JOIN 
    ActiveUsers u ON t.TagName IN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) 
        FROM Posts p 
        JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        WHERE p.OwnerUserId = u.UserId AND p.PostTypeId = 1
    ) 
WHERE 
    t.Rank <= 10 
    AND u.UserRank <= 5 
ORDER BY 
    t.TagFrequency DESC, u.UpVotes DESC;
