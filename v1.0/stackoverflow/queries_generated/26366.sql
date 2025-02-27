WITH TagStatistics AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.Id, t.TagName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserId AS CloserUserId,
        ph.CreationDate AS CloseDate,
        c.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes c ON jsonb_extract_path_text(ph.Text::jsonb, 'CloseReasonId')::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    t.TagName,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.AverageUserReputation,
    cp.Title AS ClosedPostTitle,
    cp.CloseDate,
    cp.CloseReason,
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation
FROM 
    TagStatistics t
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || t.TagName || '%')
LEFT JOIN 
    TopUsers tu ON tu.UserRank = 1
WHERE 
    t.PostCount > 0
ORDER BY 
    t.PostCount DESC
LIMIT 10;
