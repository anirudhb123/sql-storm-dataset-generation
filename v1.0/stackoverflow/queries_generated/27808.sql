WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
), 
PostHistoryStatistics AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY SUM(u.Reputation) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.CommentCount,
    ts.AvgUserReputation,
    phs.EditCount,
    phs.HistoryTypes,
    tu.DisplayName AS TopUser,
    tu.BadgeCount,
    tu.TotalReputation
FROM 
    TagStatistics ts
LEFT JOIN 
    PostHistoryStatistics phs ON ts.PostCount > 0
LEFT JOIN 
    (SELECT * FROM TopUsers WHERE Rank <= 5) tu ON ts.AvgUserReputation > 0
ORDER BY 
    ts.PostCount DESC, 
    ts.QuestionCount DESC;
