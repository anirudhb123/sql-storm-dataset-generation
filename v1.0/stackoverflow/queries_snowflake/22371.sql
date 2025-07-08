
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.VALUE
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01'::DATE)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
UserRankings AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM 
        PopularUsers
)

SELECT 
    ur.DisplayName,
    ur.PostCount,
    ur.TotalScore,
    COALESCE(rp.Tags, ARRAY_CONSTRUCT()) AS TopTags,
    rp.Score AS TopScore,
    rp.CreationDate
FROM 
    UserRankings ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.OwnerUserId
WHERE 
    ur.UserRank <= 5
ORDER BY 
    ur.TotalScore DESC, rp.Score DESC
LIMIT 10;
