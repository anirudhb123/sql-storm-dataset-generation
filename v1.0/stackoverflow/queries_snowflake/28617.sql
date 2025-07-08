
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViews,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    mau.DisplayName,
    mau.PostCount,
    mau.QuestionCount,
    mau.AnswerCount,
    mau.TotalScore,
    mau.TotalViews,
    (SELECT LISTAGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN LATERAL FLATTEN(INPUT => SPLIT(p.Tags, ',')) AS tag ON TRUE
     JOIN Tags t ON t.TagName = tag.VALUE 
     WHERE p.OwnerUserId = mau.UserId) AS MostUsedTags
FROM 
    MostActiveUsers mau
WHERE 
    mau.UserRank <= 10
ORDER BY 
    mau.UserRank;
