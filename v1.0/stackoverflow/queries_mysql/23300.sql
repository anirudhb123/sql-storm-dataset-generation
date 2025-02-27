
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        CASE 
            WHEN COUNT(b.Id) > 10 THEN 'Gold'
            WHEN COUNT(b.Id) > 5 THEN 'Silver'
            ELSE 'Bronze'
        END AS BadgeLevel
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    rb.BadgeLevel,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(pvc.UpVotes) AS TotalUpVotes,
    SUM(pvc.DownVotes) AS TotalDownVotes,
    AVG(rp.Score) AS AvgScore,
    AVG(rp.ViewCount) AS AvgViewCount,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    Users u
JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId 
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    (SELECT 
        p.OwnerUserId, 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName
     FROM 
        Posts p
     JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
         , (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) numbers 
     ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    ) AS t ON t.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id,
    u.DisplayName,
    rb.BadgeLevel
HAVING 
    COUNT(DISTINCT rp.PostId) > 5 
ORDER BY 
    AvgScore DESC, 
    TotalPosts DESC 
LIMIT 10 OFFSET 0;
