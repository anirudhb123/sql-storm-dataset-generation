WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        COALESCE(AVG(v.BountyAmount) FILTER (WHERE v.VoteTypeId = 8), 0) AS AvgBountyAmount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FilteredTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS TagRank
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0 AND t.Count > 1
)
SELECT 
    up.UserId,
    up.PostCount,
    up.TotalBounty,
    up.TotalBadges,
    up.AvgBountyAmount,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rt.TagName AS MostPopularTag
FROM 
    UserStatistics up
LEFT JOIN 
    RankedPosts rp ON up.PostCount > 10 AND rp.PostRank <= 5
LEFT JOIN 
    (
        SELECT 
            t.TagName,
            ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY t.Count DESC) AS Rn
        FROM 
            FilteredTags t
    ) rt ON rt.Rn = 1
ORDER BY 
    up.TotalBounty DESC, 
    rp.Score DESC NULLS LAST
LIMIT 50;
