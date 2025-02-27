
WITH TagStats AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
            SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL 
            SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserBadgeCounts AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.OwnerUserId
),
TopTags AS (
    SELECT
        Tag,
        PostCount,
        @rownum := @rownum + 1 AS Rank
    FROM 
        TagStats, (SELECT @rownum := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    ph.LastEditDate,
    tt.Tag,
    tt.PostCount
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryStats ph ON u.Id = ph.OwnerUserId
JOIN 
    TopTags tt ON tt.Rank <= 5  
WHERE 
    u.Reputation > 1000  
ORDER BY 
    u.Reputation DESC, 
    tt.PostCount DESC;
