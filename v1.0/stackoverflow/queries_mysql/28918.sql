mysql
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AverageReputation,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS TopUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        t.Count > 0
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageReputation,
        TopUsers, 
        @row_number := @row_number + 1 AS RN
    FROM 
        TagStatistics, (SELECT @row_number := 0) AS rn
    ORDER BY 
        PostCount DESC
)

SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AverageReputation,
    tt.TopUsers,
    (SELECT GROUP_CONCAT(DISTINCT p.Title SEPARATOR ', ') 
     FROM Posts p 
     WHERE p.Tags LIKE CONCAT('%', tt.TagName, '%') 
       AND p.CreationDate >= CURDATE() - INTERVAL 30 DAY) AS RecentPosts
FROM 
    TopTags tt
WHERE 
    tt.RN <= 10
ORDER BY 
    tt.PostCount DESC;
