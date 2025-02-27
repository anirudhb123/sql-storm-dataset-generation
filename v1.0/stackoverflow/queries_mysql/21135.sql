
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        t.TagName
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM (SELECT @rownum := @rownum + 1 AS n
               FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) numbers,
               (SELECT @rownum := 0) r) numbers
         WHERE @rownum < CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t
    ) ON true
    WHERE 
        p.PostTypeId = 1
), 
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS BadgeScore,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.RankScore,
    rt.TagName,
    up.UserId,
    up.BadgeScore,
    up.AvgReputation,
    CASE 
        WHEN up.BadgeScore IS NULL THEN 'No Badges'
        WHEN up.BadgeScore > 5 THEN 'Expert'
        ELSE 'Novice'
    END AS UserStatus
FROM 
    RankedPosts rp
JOIN 
    PostTags rt ON rp.PostId = rt.PostId
LEFT JOIN 
    UserMetrics up ON rp.OwnerUserId = up.UserId
WHERE 
    (rp.UpvoteCount - rp.DownvoteCount) > 0
    AND rp.RankScore <= 5  
ORDER BY 
    rp.PostTypeId, rp.Score DESC
LIMIT 100;
