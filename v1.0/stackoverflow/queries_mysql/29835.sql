
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(BOTH '<>' FROM p.Tags), '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
TagPopularity AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag 
    FROM 
        TagPopularity
    WHERE 
        TagCount > 100 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.QuestionCount,
        ur.AnswerCount,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        UserReputation ur,
        (SELECT @rownum := 0) r
    ORDER BY 
        ur.Reputation DESC, ur.QuestionCount DESC
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        COUNT(c.Id) AS CommentsCount,
        p.OwnerUserId 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.LastActivityDate >= (NOW() - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId, p.OwnerUserId
)
SELECT 
    tu.UserId,
    u.DisplayName,
    ta.Tag,
    ap.PostId,
    ap.Title,
    ap.CreationDate,
    ap.Score,
    ap.ViewCount,
    ap.CommentsCount
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
JOIN 
    PopularTags ta ON EXISTS (
        SELECT 1 
        FROM PostTagCounts ptc 
        WHERE ptc.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = tu.UserId)
        AND ptc.Tag = ta.Tag
    )
JOIN 
    ActivePosts ap ON ap.OwnerUserId = tu.UserId
ORDER BY 
    tu.UserRank, ap.Score DESC;
