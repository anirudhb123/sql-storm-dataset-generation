
WITH TagCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON 
        CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1 
                WHEN v.VoteTypeId = 3 THEN -1 
                ELSE 0 
            END) AS ReputationScore, 
        COUNT(DISTINCT p.Id) AS AnswerPostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    WHERE 
        p.PostTypeId = 2
    GROUP BY 
        u.Id, u.DisplayName
), 
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        @rank := @rank + 1 AS TagRank
    FROM 
        TagCounts, (SELECT @rank := 0) r
    WHERE 
        PostCount > 5
    ORDER BY 
        PostCount DESC
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        ReputationScore,
        AnswerPostCount,
        @userRank := @userRank + 1 AS UserRank
    FROM 
       UserReputation, (SELECT @userRank := 0) r
    WHERE 
        ReputationScore > 0
    ORDER BY 
        ReputationScore DESC
)
SELECT 
    t.TagName, 
    t.PostCount, 
    u.DisplayName AS TopUser, 
    u.ReputationScore,
    t.TagRank,
    u.UserRank
FROM 
    TopTags t
JOIN 
    TopUsers u ON u.AnswerPostCount > 10
WHERE 
    t.TagRank <= 10 AND u.UserRank <= 20
ORDER BY 
    t.PostCount DESC, u.ReputationScore DESC;
