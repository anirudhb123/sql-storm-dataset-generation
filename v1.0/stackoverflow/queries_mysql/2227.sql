
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
), 
PostScores AS (
    SELECT 
        p.OwnerUserId,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.OwnerUserId
), 
UserRanking AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.Views,
        ps.TotalScore,
        ps.PostCount,
        @rank := IF(@prev_reputation = us.Reputation AND @prev_score = ps.TotalScore, @rank, @rank + 1) AS UserRank,
        @prev_reputation := us.Reputation,
        @prev_score := ps.TotalScore
    FROM 
        UserStatistics us,
        (SELECT @rank := 0, @prev_reputation := NULL, @prev_score := NULL) AS vars,
        PostScores ps 
    WHERE 
        us.UserId = ps.OwnerUserId
    ORDER BY 
        us.Reputation DESC, ps.TotalScore DESC
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.Views,
    ur.TotalScore,
    ur.PostCount,
    ur.UserRank,
    COALESCE(t.TagName, 'No Tags') AS MostFrequentTag
FROM 
    UserRanking ur
LEFT JOIN 
    (
        SELECT 
            p.OwnerUserId, 
            t.TagName,
            COUNT(*) AS TagCount
        FROM 
            Posts p,
            (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
             FROM Posts p
             CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
             WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS t
        GROUP BY 
            p.OwnerUserId, t.TagName
        ORDER BY 
            TagCount DESC
    ) t ON ur.UserId = t.OwnerUserId
WHERE 
    ur.UserRank <= 100
ORDER BY 
    ur.UserRank;
