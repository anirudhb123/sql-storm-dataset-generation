
WITH PopularQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.AcceptedAnswerId IS NOT NULL
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
QuestionTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', numbers.n), '>', -1) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
)
SELECT 
    q.PostId,
    q.Title,
    q.Score,
    qt.Tags,
    u.DisplayName AS TopUser,
    u.Reputation
FROM 
    PopularQuestions q
LEFT JOIN 
    QuestionTags qt ON q.PostId = qt.PostId
LEFT JOIN 
    Users u ON u.Id = (SELECT UserId FROM Votes v WHERE v.PostId = q.PostId AND v.VoteTypeId = 2 ORDER BY v.CreationDate DESC LIMIT 1)
WHERE 
    q.RankByScore <= 10
ORDER BY 
    q.Score DESC, q.CreationDate DESC;
