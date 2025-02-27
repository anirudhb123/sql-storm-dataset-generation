
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS a) AS numbers
    WHERE PostTypeId = 1 AND CHAR_LENGTH(Tags) > 2
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @row_number := @row_number + 1 AS TagRank
    FROM TagCounts, (SELECT @row_number := 0) AS r
    ORDER BY PostCount DESC
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(*) AS QuestionAnswered,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.PostTypeId = 2  
    GROUP BY u.Id, u.DisplayName
    ORDER BY TotalScore DESC
    LIMIT 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        P.Name AS PostHistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes P ON ph.PostHistoryTypeId = P.Id
    WHERE ph.CreationDate > NOW() - INTERVAL 30 DAY
    ORDER BY ph.CreationDate DESC
    LIMIT 10
)

SELECT 
    t.TagName,
    t.PostCount,
    u.UserName,
    u.QuestionAnswered,
    u.TotalScore,
    r.CreationDate,
    r.PostHistoryType
FROM TopTags t
JOIN TopUsers u ON u.QuestionAnswered >= (SELECT MAX(PostCount) FROM TopTags)
JOIN RecentPostHistory r ON r.PostId IN (
    SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', t.TagName, '%')
)
ORDER BY t.PostCount DESC, u.TotalScore DESC;
