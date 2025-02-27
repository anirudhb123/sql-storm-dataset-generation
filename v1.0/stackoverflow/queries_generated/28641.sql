WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount, 
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount,
        AVG(COALESCE(u.Reputation, 0)) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViewCount,
        AvgUserReputation,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS PostCountRank
    FROM 
        TagStats
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS PostRankInTag
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.TotalScore,
    tt.TotalViewCount,
    tt.AvgUserReputation,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score
FROM 
    TopTags tt
LEFT JOIN 
    TopPosts tp ON tt.TagName = tp.TagName
WHERE 
    tp.PostRankInTag <= 3
ORDER BY 
    tt.ScoreRank, tt.PostCountRank, tp.Score DESC;
