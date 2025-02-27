WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE 
            WHEN pt.Name = 'Answer' THEN 1
            ELSE 0 
        END) AS AnswerCount,
        SUM(CASE 
            WHEN pt.Name = 'Question' THEN 1
            ELSE 0 
        END) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Users u ON u.Id = p.OwnerUserId
    GROUP BY
        t.TagName
),
PostHistoryCount AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.CommentCount,
    ts.AverageUserReputation,
    COALESCE(phc.HistoryCount, 0) AS TotalHistoryCount,
    CASE 
        WHEN ts.PostCount > 0 THEN 
            (CAST(ts.AnswerCount AS FLOAT) / NULLIF(ts.PostCount, 0)) * 100 
        ELSE 0 
    END AS AnswerToPostRatio,
    CASE 
        WHEN ts.PostCount > 0 THEN 
            (CAST(ts.CommentCount AS FLOAT) / NULLIF(ts.PostCount, 0)) * 100 
        ELSE 0 
    END AS CommentToPostRatio
FROM
    TagStatistics ts
LEFT JOIN 
    PostHistoryCount phc ON phc.PostId IN (
        SELECT 
            DISTINCT p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY
    ts.PostCount DESC, 
    ts.TagName;
