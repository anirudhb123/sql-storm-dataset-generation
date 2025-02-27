
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount, 
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(IFNULL(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        us.*, 
        @rank := IF(@prev_upvotes = (us.Upvotes - us.Downvotes), @rank, @rank + 1) AS UserRank,
        @prev_upvotes := (us.Upvotes - us.Downvotes)
    FROM 
        UserStats us, (SELECT @rank := 0, @prev_upvotes := NULL) r
    ORDER BY 
        us.Upvotes - us.Downvotes DESC, us.PostCount DESC
)
SELECT 
    ru.UserId, 
    ru.DisplayName, 
    ru.PostCount, 
    ru.QuestionCount, 
    ru.AnswerCount, 
    ru.Upvotes, 
    ru.Downvotes, 
    ru.TotalBadges,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
     FROM Posts p2 
     LEFT JOIN (
         SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p2.Tags, ',', numbers.n), ',', -1)) AS tag
         FROM (
             SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
         ) numbers
         WHERE CHAR_LENGTH(p2.Tags) - CHAR_LENGTH(REPLACE(p2.Tags, ',', '')) >= numbers.n - 1
     ) AS tag ON TRUE 
     LEFT JOIN Tags t ON t.TagName = tag 
     WHERE p2.OwnerUserId = ru.UserId) AS PopularTags
FROM 
    RankedUsers ru
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.UserRank;
