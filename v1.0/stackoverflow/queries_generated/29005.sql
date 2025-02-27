WITH TagArray AS (
    SELECT 
        Id AS PostId, 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1 -- Only questions
),
TagCounts AS (
    SELECT 
        Tag, 
        COUNT(PostId) AS Count 
    FROM 
        TagArray 
    GROUP BY 
        Tag 
    HAVING 
        COUNT(PostId) > 5 -- Only consider tags used in more than 5 questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS DownVotes,
        SUM(COALESCE(b.Class = 1, 0)::int) AS GoldBadges,
        SUM(COALESCE(b.Class = 2, 0)::int) AS SilverBadges,
        SUM(COALESCE(b.Class = 3, 0)::int) AS BronzeBadges
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
        UserId, 
        DisplayName,
        QuestionCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY QuestionCount DESC, UpVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    t.Tag,
    COUNT(DISTINCT tu.UserId) AS ActiveUsers,
    AVG(tu.QuestionCount) AS AvgQuestions,
    SUM(tu.UpVotes) AS TotalUpVotes,
    SUM(tu.DownVotes) AS TotalDownVotes,
    SUM(tu.GoldBadges) AS TotalGoldBadges,
    SUM(tu.SilverBadges) AS TotalSilverBadges,
    SUM(tu.BronzeBadges) AS TotalBronzeBadges
FROM 
    TagCounts t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.Tag || '%'
JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
GROUP BY 
    t.Tag
ORDER BY 
    ActiveUsers DESC, TotalUpVotes DESC
LIMIT 10;
