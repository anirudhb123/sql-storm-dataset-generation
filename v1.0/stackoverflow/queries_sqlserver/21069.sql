
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
        AND p.Score IS NOT NULL
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '>') AS Tag
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) >= 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -3, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Owner,
    r.RankScore,
    th.PostCount,
    th.TotalScore,
    pt.TagName,
    phs.HistoryCount,
    phs.Comments
FROM 
    Posts p
LEFT JOIN 
    RankedPosts r ON p.Id = r.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    TopUsers th ON u.Id = th.Id
LEFT JOIN 
    PopularTags pt ON pt.TagName = STRING_SPLIT(p.Tags, '>').value
LEFT JOIN 
    PostHistoryStats phs ON p.Id = phs.PostId
WHERE 
    (th.TotalScore > 500 OR r.RankScore = 1)
    AND p.CreationDate IS NOT NULL
    AND (p.ClosedDate IS NULL OR p.ClosedDate <= DATEADD(MONTH, -1, '2024-10-01 12:34:56'))
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
