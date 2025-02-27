
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(REPLACE(REPLACE(p.Tags, '<', ''), '>', ''), ',') AS tag
    JOIN 
        Tags t ON t.TagName = TRIM(tag.value)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year' 
    GROUP BY 
        p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        ps.TotalPosts,
        ps.TotalScore,
        ps.AvgViews,
        DENSE_RANK() OVER (ORDER BY ps.TotalScore DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    tu.DisplayName,
    tu.UserRank,
    COALESCE(ph.Comment, 'No Closure Reason') AS ClosureReason
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11) 
LEFT JOIN 
    CloseReasonTypes crt ON crt.Id = TRY_CAST(ph.Comment AS INT) 
JOIN 
    TopUsers tu ON tu.TotalPosts > 10 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
