WITH TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageUserReputation,
        STDEV(u.Reputation) AS ReputationStandardDeviation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%') 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS Comments,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),

MergedStatistics AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AverageUserReputation,
        ts.ReputationStandardDeviation,
        phd.HistoryCount,
        phd.LastHistoryDate
    FROM 
        TagStatistics ts
    LEFT JOIN 
        PostHistoryDetails phd ON ts.PostCount > 0 AND phd.PostId IN 
        (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%<', ts.TagName, '>%'))
)

SELECT 
    ms.TagName,
    ms.PostCount,
    ms.QuestionCount,
    ms.AnswerCount,
    ms.AverageUserReputation,
    ms.ReputationStandardDeviation,
    ms.HistoryCount,
    ms.LastHistoryDate
FROM 
    MergedStatistics ms
WHERE 
    ms.PostCount > 0
ORDER BY 
    ms.PostCount DESC, 
    ms.QuestionCount DESC;
