
WITH TagCounts AS (
    SELECT 
        TRIM(BOTH '>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) 
         -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10
), 
UserEngagement AS (
    SELECT 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id 
    GROUP BY 
        u.DisplayName
), 
TopUsers AS (
    SELECT 
        DisplayName,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY QuestionCount DESC, UpVotes DESC) AS UserRank
    FROM 
        UserEngagement
)
SELECT 
    t.Tag,
    tu.DisplayName,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tu.UserRank
FROM 
    TopTags t
JOIN 
    TopUsers tu ON t.PostCount = tu.QuestionCount
WHERE 
    tu.UserRank <= 10
ORDER BY 
    t.PostCount DESC, 
    tu.UpVotes DESC;
