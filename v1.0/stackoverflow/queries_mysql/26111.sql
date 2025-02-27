
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT a.N + b.N * 10 + 1 n 
        FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
        ORDER BY n
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
TagFrequency AS (
    SELECT 
        Tag,
        COUNT(*) AS Frequency
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalQuestions,
        ua.UpvotedQuestions,
        ua.DownvotedQuestions,
        ua.TotalComments,
        @row := @row + 1 AS UserRank
    FROM 
        UserActivity ua, (SELECT @row := 0) r
    WHERE 
        ua.TotalQuestions > 10 
    ORDER BY 
        ua.TotalQuestions DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalQuestions,
    tu.UpvotedQuestions,
    tu.DownvotedQuestions,
    tu.TotalComments,
    tf.Tag,
    tf.Frequency
FROM 
    TopUsers tu
JOIN 
    TagFrequency tf ON tf.Tag IN (
        SELECT Tag 
        FROM ProcessedTags pt 
        WHERE pt.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = tu.UserId
        )
    )
ORDER BY 
    tu.UserRank, tf.Frequency DESC;
