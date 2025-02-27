
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount,
        p.Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.Score > 10
),
UserScore AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        value AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') AS Tags
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        value
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    u.DisplayName,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    us.TotalScore,
    us.PostCount,
    COALESCE(rt.Tag, 'No Tags') AS PopularTag
FROM 
    RankedPosts ps
JOIN 
    Users u ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserScore us ON us.UserId = u.Id
LEFT JOIN 
    PopularTags rt ON rt.PostCount = (
        SELECT 
            MAX(PostCount) 
        FROM 
            PopularTags 
        WHERE 
            Tag IN (SELECT value FROM STRING_SPLIT(ps.Tags, ','))
    )
WHERE 
    ps.Rank = 1
ORDER BY 
    us.TotalScore DESC, ps.ViewCount DESC;
