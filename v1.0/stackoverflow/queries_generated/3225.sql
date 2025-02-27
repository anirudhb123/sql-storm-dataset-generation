WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(v.UserId IS NOT NULL)::int AS TotalFavorites
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    rp.Title,
    rp.Score,
    rt.Tag,
    us.TotalBounty,
    us.TotalFavorites,
    COALESCE(rp.CommentCount, 0) AS CommentCount
FROM 
    Users u
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    PopularTags rt ON rt.Tag = ANY(string_to_array(rp.Title, ' '))
WHERE 
    rp.PostRank = 1
ORDER BY 
    us.TotalBounty DESC, rp.Score DESC
LIMIT 100;
