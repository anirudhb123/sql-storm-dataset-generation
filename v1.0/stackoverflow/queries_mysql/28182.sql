
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT @row := @row + 1 AS n FROM 
        (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t1,
        (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) t2,
        (SELECT @row := 0) AS r
    ) n
    WHERE  
        PostTypeId = 1 
        AND n.n <= (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')) + 1)
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    ORDER BY PostCount DESC
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        TotalViews,
        TotalScore,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        UserActivity, (SELECT @user_rank := 0) r
    ORDER BY QuestionsAsked DESC
)

SELECT 
    ut.UserId,
    ut.DisplayName,
    tt.Tag,
    tt.PostCount,
    ut.QuestionsAsked,
    ut.TotalViews,
    ut.TotalScore
FROM 
    ActiveUsers ut
JOIN 
    (SELECT 
        tt.Tag,
        tt.PostCount,
        tt.Rank
     FROM 
        TopTags tt
     WHERE 
        tt.Rank <= 5) AS tt ON ut.UserRank <= 10 
ORDER BY 
    tt.PostCount DESC, ut.TotalViews DESC, ut.TotalScore DESC;
