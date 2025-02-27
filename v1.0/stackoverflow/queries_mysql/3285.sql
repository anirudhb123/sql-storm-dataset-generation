
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', n.n), ',', -1) AS Tag,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 MONTH
    GROUP BY 
        Tag
    ORDER BY 
        PostCount DESC
    LIMIT 10
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
            FIND_IN_SET(Tag, ps.Tags)
    )
WHERE 
    ps.Rank = 1
ORDER BY 
    us.TotalScore DESC, ps.ViewCount DESC;
