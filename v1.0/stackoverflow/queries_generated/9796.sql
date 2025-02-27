WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Questions only
        p.CreationDate > NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
),
PostDetail AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        tu.UserId,
        tu.DisplayName AS Author,
        tu.TotalViews,
        tu.TotalScore
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CreationDate,
    pd.Author,
    pd.TotalViews,
    pd.TotalScore,
    COALESCE(pt.Name, 'Other') AS PostType,
    COALESCE(ct.Name, 'No Close Reason') AS CloseReason
FROM 
    PostDetail pd
LEFT JOIN 
    PostTypes pt ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Id = pd.PostId AND p.PostTypeId = pt.Id
    )
LEFT JOIN 
    PostHistory ph ON ph.PostId = pd.PostId AND ph.PostHistoryTypeId = 10
LEFT JOIN 
    CloseReasonTypes ct ON ph.Comment::int = ct.Id
WHERE 
    pd.Rank <= 5
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
