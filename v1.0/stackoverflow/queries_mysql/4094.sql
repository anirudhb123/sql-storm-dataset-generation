
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(BOTH '<>' FROM tag) AS tag FROM Posts, JSON_UNQUOTE(JSON_EXTRACT(CONVERT(CONCAT('["', REPLACE(p.Tags, '><', '","'), '"]'), JSON_UNQUOTE)) as JSON)) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag)
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
        p.CreationDate > NOW() - INTERVAL 1 YEAR 
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
    CloseReasonTypes crt ON crt.Id = CAST(ph.Comment AS UNSIGNED) 
JOIN 
    TopUsers tu ON tu.TotalPosts > 10 
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
