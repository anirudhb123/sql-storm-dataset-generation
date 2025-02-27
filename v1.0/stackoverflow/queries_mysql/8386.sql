
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
         FROM Posts p
         JOIN (SELECT @rownum := @rownum + 1 AS n FROM 
               (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
                UNION ALL SELECT 10) t1,
               (SELECT @rownum := 0) t2) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), UserScore AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation >= 1000 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.TotalScore,
    up.QuestionCount,
    bp.PostID,
    bp.Title,
    bp.CreationDate,
    bp.Tags
FROM 
    UserScore up
JOIN 
    RankedPosts bp ON up.UserID = bp.UserPostRank
WHERE 
    bp.UserPostRank <= 5 
ORDER BY 
    up.TotalScore DESC, bp.CreationDate DESC;
