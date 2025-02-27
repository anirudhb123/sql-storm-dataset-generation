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
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id
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
        u.Id
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
    COALESCE(rp.Tags, '{}') AS TopTags,
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
LIMIT 10;

-- This query fetches the top 5 users with the highest total score and their top posts
-- It utilizes CTEs for organizing data and includes window functions for rankings.
-- It also handles NULL logic for users with no posts and string manipulation for tags.
