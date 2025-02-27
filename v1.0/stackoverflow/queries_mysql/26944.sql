
WITH PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        GROUP_CONCAT(DISTINCT TRIM(BOTH '<>' FROM tag_names) SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        (SELECT TRIM(BOTH '<>' FROM tag_name) AS tag_names FROM Posts) tag_names ON FIND_IN_SET('<>' , p.Tags) 
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_names)
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeQuestions,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.QuestionCount,
        ua.PositiveQuestions,
        ua.NegativeQuestions,
        ua.TotalBounties,
        @rank := @rank + 1 AS Rank
    FROM 
        UserActivity ua, (SELECT @rank := 0) r
    ORDER BY 
        ua.Reputation DESC
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.AnswerCount,
    pa.Tags,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.QuestionCount AS TopUserQuestions,
    tu.PositiveQuestions AS TopUserPositiveQuestions,
    tu.NegativeQuestions AS TopUserNegativeQuestions,
    tu.TotalBounties AS TopUserTotalBounties
FROM 
    PostAggregates pa
JOIN 
    TopUsers tu ON tu.QuestionCount > 0
WHERE 
    pa.Score > 10 
ORDER BY 
    pa.ViewCount DESC,
    pa.CreationDate DESC
LIMIT 10;
