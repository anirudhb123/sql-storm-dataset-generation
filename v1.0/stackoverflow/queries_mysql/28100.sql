
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
), TagStats AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT pt.PostId) AS QuestionCount,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    GROUP BY 
        pt.Tag
), RankedTags AS (
    SELECT 
        ts.Tag,
        ts.QuestionCount,
        ts.UniqueUsers,
        ts.TotalAnswers,
        ts.TotalViews,
        ts.AverageScore,
        @rank:=@rank+1 AS Rank
    FROM 
        TagStats ts,
        (SELECT @rank:=0) r
    ORDER BY 
        ts.QuestionCount DESC, ts.TotalViews DESC
)
SELECT 
    rt.Tag,
    rt.QuestionCount,
    rt.UniqueUsers,
    rt.TotalAnswers,
    rt.TotalViews,
    rt.AverageScore
FROM 
    RankedTags rt
WHERE 
    rt.Rank <= 10;
