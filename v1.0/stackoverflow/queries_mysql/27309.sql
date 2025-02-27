
WITH RankedUserPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS UserRank
    FROM Posts p
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, r.TotalPosts, r.QuestionCount, r.AnswerCount
    FROM Users u
    JOIN RankedUserPosts r ON u.Id = r.OwnerUserId
    WHERE r.UserRank <= 10  
),
PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        t.TagName,
        COUNT(*) AS TagCount
    FROM Posts p
    JOIN (
        SELECT 
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM Posts p
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 -- Extend as necessary for the number of tags
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) t ON p.Id = t.PostId
    GROUP BY p.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalTagCount
    FROM PostTagCounts
    GROUP BY TagName
    ORDER BY TotalTagCount DESC
    LIMIT 5  
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tg.TagName,
    tg.TotalTagCount
FROM TopUsers tu
JOIN TopTags tg ON tg.TagName IN (SELECT TagName FROM PostTagCounts)
ORDER BY tu.Reputation DESC, tg.TotalTagCount DESC;
