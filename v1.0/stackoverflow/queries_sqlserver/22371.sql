
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    CROSS APPLY 
        (SELECT value AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
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
    COALESCE(rp.Tags, '') AS TopTags,
    rp.Score AS TopScore,
    rp.CreationDate
FROM 
    UserRankings ur
LEFT JOIN 
    RankedPosts rp ON ur.UserId = rp.PostId
WHERE 
    ur.UserRank <= 5
ORDER BY 
    ur.TotalScore DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
