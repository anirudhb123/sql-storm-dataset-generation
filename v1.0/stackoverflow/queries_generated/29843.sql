WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostEngagement AS (
    SELECT
        p.Id,
        p.Title,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS EditCount FROM PostHistory WHERE PostHistoryTypeId IN (4, 5, 6) GROUP BY PostId) ph ON p.Id = ph.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgReputation,
    ts.TopUsers,
    pe.Title,
    pe.CommentCount,
    pe.VoteCount,
    pe.EditCount
FROM 
    TagStatistics ts
JOIN 
    PostEngagement pe ON pe.Id IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    ts.PostCount DESC, ts.QuestionCount DESC, ts.AvgReputation DESC;
