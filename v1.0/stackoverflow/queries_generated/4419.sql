WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(p.Id) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    CASE 
        WHEN CUP.Comment IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus,
    tu.TotalQuestions,
    tu.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
LEFT JOIN 
    ClosedPostHistory CUP ON rp.Id = CUP.PostId
WHERE 
    rp.rn = 1 -- Get only the latest question for each user
ORDER BY 
    tu.TotalScore DESC, 
    rp.CreationDate DESC 
LIMIT 50;
