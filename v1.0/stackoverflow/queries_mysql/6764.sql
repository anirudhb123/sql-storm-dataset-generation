
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentScore,
        BadgeCount,
        @rank := IF(@reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @reputation := NULL) r
    ORDER BY 
        Reputation DESC, PostCount DESC
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.PostCount,
    ru.QuestionCount,
    ru.AnswerCount,
    ru.CommentScore,
    ru.BadgeCount,
    COALESCE(bnt.TagName, 'No Tag') AS MostPopularTag,
    COUNT(DISTINCT pl.RelatedPostId) AS LinkedPosts
FROM 
    RankedUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    (SELECT 
         TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName,
         COUNT(*) AS TagCount 
     FROM 
         Posts 
     JOIN 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
     ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1 
     GROUP BY 
         TagName 
     ORDER BY 
         TagCount DESC 
     LIMIT 1) bnt ON true
GROUP BY 
    ru.UserId, ru.DisplayName, ru.Reputation, ru.PostCount, ru.QuestionCount, 
    ru.AnswerCount, ru.CommentScore, ru.BadgeCount, bnt.TagName
ORDER BY 
    ru.Reputation DESC, ru.PostCount DESC
LIMIT 100;
