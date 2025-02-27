
WITH TagCount AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS value
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCount
    WHERE 
        PostCount > 5 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tt.Tag,
    tt.PostCount,
    ub.UserId,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' + tt.Tag + '%')) AS TotalVotesForTag
FROM 
    TopTags tt
JOIN 
    Posts p ON p.Tags LIKE '%' + tt.Tag + '%'
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    tt.PostCount DESC, ub.BadgeCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
