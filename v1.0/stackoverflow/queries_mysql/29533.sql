
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON 
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(IFNULL(v.Direction, 0)) AS TotalVotes,
        SUM(IF(b.Class = 1, 1, 0)) AS GoldBadges,
        SUM(IF(b.Class = 2, 1, 0)) AS SilverBadges,
        SUM(IF(b.Class = 3, 1, 0)) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(VoteTypeId) AS Direction
         FROM 
            Votes 
         WHERE 
            VoteTypeId IN (2, 3) 
         GROUP BY 
            PostId) v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveTags AS (
    SELECT 
        pt.Tag,
        COUNT(pt.PostId) AS TagUsage
    FROM 
        PostTags pt
    GROUP BY 
        pt.Tag
    ORDER BY 
        TagUsage DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserName,
    u.QuestionCount,
    u.TotalVotes,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    mt.Tag AS MostUsedTag,
    mt.TagUsage
FROM 
    UserPostStats u
CROSS JOIN 
    MostActiveTags mt
ORDER BY 
    u.TotalVotes DESC, u.QuestionCount DESC;
