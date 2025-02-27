
WITH TagUsage AS (
    SELECT
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '> <') 
    WHERE
        PostTypeId = 1  
    GROUP BY
        TRIM(value)
),
PopularTags AS (
    SELECT
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagUsage
),
UserEngagement AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
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
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT
        DisplayName,
        QuestionCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY QuestionCount DESC) AS UserRank
    FROM
        UserEngagement
)
SELECT 
    pu.TagName,
    pu.PostCount,
    tu.DisplayName AS TopUser,
    tu.QuestionCount,
    tu.UpVotes,
    tu.DownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM 
    PopularTags pu
JOIN 
    TopUsers tu ON pu.TagRank = 1 
ORDER BY 
    pu.PostCount DESC, tu.QuestionCount DESC;
