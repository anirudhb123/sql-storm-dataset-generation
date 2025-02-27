
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS date)
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
PostHistoryTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        STRING_SPLIT(p.Tags, ',') AS tag ON 1=1
    JOIN 
        Tags t ON t.TagName = LTRIM(RTRIM(tag.value))
    WHERE 
        ph.CreationDate >= CAST(DATEADD(month, -6, '2024-10-01') AS date)
    GROUP BY 
        ph.PostId
)
SELECT 
    up.OwnerUserId,
    u.DisplayName AS UserDisplayName,
    up.TotalScore,
    up.PostCount,
    up.AvgViewCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    COALESCE(pht.Tags, 'No Tags') AS PostTags,
    CASE 
        WHEN pp.Score >= 0 THEN 'Non-negative Score'
        ELSE 'Negative Score'
    END AS ScoreCategory
FROM 
    TopUsers up
JOIN 
    RankedPosts pp ON up.OwnerUserId = pp.OwnerUserId
LEFT JOIN 
    PostHistoryTags pht ON pp.PostId = pht.PostId
JOIN 
    Users u ON u.Id = up.OwnerUserId
WHERE 
    pp.RN = 1 
    AND up.PostCount > 10
ORDER BY 
    up.TotalScore DESC, 
    pp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
