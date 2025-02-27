
WITH TagArray AS (
    SELECT 
        Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts 
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
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
        COUNT(PostId) > 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes,
        SUM(COALESCE(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END, 0)) AS GoldBadges,
        SUM(COALESCE(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END, 0)) AS SilverBadges,
        SUM(COALESCE(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END, 0)) AS BronzeBadges
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
        @rank := IF(@prev_question_count = QuestionCount, @rank, @rank + 1) AS Rank,
        @prev_question_count := QuestionCount
    FROM 
        UserActivity, (SELECT @rank := 0, @prev_question_count := NULL) r
    ORDER BY 
        QuestionCount DESC, UpVotes DESC
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
    Posts p ON p.Tags LIKE CONCAT('%', t.Tag, '%')
JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
GROUP BY 
    t.Tag
ORDER BY 
    ActiveUsers DESC, TotalUpVotes DESC
LIMIT 10;
