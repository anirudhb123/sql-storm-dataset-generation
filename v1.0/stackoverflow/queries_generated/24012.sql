WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RN,
        COALESCE(NULLIF(u.Reputation, 0), 1) AS SafeReputation,
        CASE 
            WHEN p.Score > 10 THEN 'High'
            WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate BETWEEN NOW() - INTERVAL '2 years' AND NOW()
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    tu.DisplayName,
    tu.PositivePostCount,
    tu.NegativePostCount,
    CASE 
        WHEN tu.PositivePostCount > 10 AND tu.NegativePostCount = 0 THEN 'Sought After'
        WHEN tu.NegativePostCount > 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS UserReputationStatus,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount,
    STRING_AGG(DISTINCT CONCAT(pt.Name, ': ', pt.Id), ', ') AS PostHistoryTypes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
WHERE 
    rp.RN = 1
GROUP BY 
    rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.AnswerCount, tu.DisplayName, tu.PositivePostCount, tu.NegativePostCount
ORDER BY 
    rp.Score DESC, tu.PositivePostCount DESC
LIMIT 50
OFFSET 0;

-- Additionally, the UNION for the existence of certain conditions
WITH ExistingPosts AS (
    SELECT 
        Id,
        OwnerUserId,
        CASE 
            WHEN AnswerCount > 0 THEN 'Has Answers'
            ELSE 'No Answers'
        END AS AnswerStatus
    FROM 
        Posts
),
CatalogedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        EXISTS (
            SELECT 1 FROM ExistingPosts ep WHERE ep.OwnerUserId = u.Id
        ) AS HasPosts
    FROM 
        Users u
)
SELECT 
    cu.DisplayName,
    CASE 
        WHEN cu.HasPosts THEN 'Active User'
        ELSE 'Silent User'
    END AS UserStatus
FROM 
    CatalogedUsers cu
WHERE 
    cu.DisplayName IS NOT NULL AND cu.DisplayName != ''
UNION ALL
SELECT 
    DISTINCT b.UserId,
    'Badge Holder' AS UserStatus
FROM 
    Badges b
WHERE 
    b.Date < NOW() - INTERVAL '1 year';
