
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
        p.CreationDate >= CAST('2024-10-01' AS DATE) - CAST(30 AS INT)   -- Converted INTERVAL to simple subtraction
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
        value AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '><')  -- Using STRING_SPLIT for tag splitting
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
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
    us.Reputation DESC, rp.ViewCount DESC;  -- Removed NULLS LAST as it's not applicable in T-SQL
