
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount IS NOT NULL AND p.Score >= 0
),
TopUsers AS (
    SELECT 
        Rank.OwnerName,
        COUNT(Rank.PostId) AS PostCount,
        SUM(Rank.ViewCount) AS TotalViews,
        SUM(Rank.Score) AS TotalScore
    FROM 
        RankedPosts Rank
    WHERE 
        Rank.PostRank <= 5  
    GROUP BY 
        Rank.OwnerName
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
UserMetrics AS (
    SELECT 
        T.OwnerName,
        T.PostCount,
        T.TotalViews,
        T.TotalScore,
        COALESCE(B.BadgeCount, 0) AS BadgeCount
    FROM 
        TopUsers T
    LEFT JOIN 
        UserBadges B ON T.OwnerName = B.DisplayName
)
SELECT 
    UM.OwnerName,
    UM.PostCount,
    UM.TotalViews,
    UM.TotalScore,
    UM.BadgeCount,
    CASE 
        WHEN UM.PostCount >= 10 THEN 'Expert'
        WHEN UM.PostCount >= 5 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsUsed
FROM 
    UserMetrics UM
LEFT JOIN 
    Posts p ON p.OwnerDisplayName = UM.OwnerName
LEFT JOIN 
    (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
     FROM 
         Posts p CROSS JOIN 
         (SELECT @rownum:=@rownum+1 AS n FROM 
          (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1,
          (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2,
          (SELECT @rownum:=0) t3) n
     WHERE 
         n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t ON TRUE
GROUP BY 
    UM.OwnerName, UM.PostCount, UM.TotalViews, UM.TotalScore, UM.BadgeCount
ORDER BY 
    UM.TotalScore DESC, UM.TotalViews DESC;
