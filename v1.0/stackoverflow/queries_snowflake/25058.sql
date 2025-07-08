
WITH TagCounts AS (
    SELECT 
        TRIM(SPLIT_PART(Tags, '><', seq)) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq -- Assuming a maximum of 1000 tags; adjust if necessary
    WHERE 
        PostTypeId = 1
        AND seq <= ARRAY_SIZE(SPLIT(Tags, '><')) -- Ensures the split does not exceed the available tags
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
