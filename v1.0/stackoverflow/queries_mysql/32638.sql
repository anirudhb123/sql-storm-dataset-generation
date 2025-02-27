
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 30 DAY
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS rn
    FROM 
        PopularTags
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalBounty,
    us.AvgPostScore,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    tt.TagName AS PopularTag
FROM 
    UserStats us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    TopTags tt ON us.Reputation > 100 AND tt.rn <= 5
WHERE 
    us.PostCount > 0
ORDER BY 
    us.Reputation DESC, rp.ViewCount DESC;
