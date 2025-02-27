WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')::int[])
    WHERE 
        p.PostTypeId = 1 -- considering only questions
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) / 3600 AS AvgResponseTimeInHours,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000 -- only consider users with respect
    GROUP BY 
        u.Id, u.DisplayName
),
MostActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AvgResponseTimeInHours,
        ua.GoldBadges,
        ua.SilverBadges,
        ua.BronzeBadges,
        pt.TagCount,
        pt.TagsList
    FROM 
        UserActivity ua
    JOIN 
        PostTagCounts pt ON ua.UserId = pt.OwnerUserId
    ORDER BY 
        ua.QuestionCount DESC, ua.AvgResponseTimeInHours ASC
    LIMIT 10
)
SELECT 
    mau.UserId,
    mau.DisplayName,
    mau.QuestionCount,
    mau.AvgResponseTimeInHours,
    mau.GoldBadges,
    mau.SilverBadges,
    mau.BronzeBadges,
    mau.TagCount,
    mau.TagsList
FROM 
    MostActiveUsers mau
ORDER BY 
    mau.QuestionCount DESC, mau.TagCount DESC;
