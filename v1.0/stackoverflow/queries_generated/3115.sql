WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
),
UserScore AS (
    SELECT 
        u.Id AS UserId, 
        COALESCE(SUM(vt.VoteTypeId = 2)::int - SUM(vt.VoteTypeId = 3)::int, 0) AS ReputationScore
    FROM 
        Users u
    LEFT JOIN 
        Votes vt ON u.Id = vt.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        us.ReputationScore
    FROM 
        RankedPosts rp
    JOIN 
        UserScore us ON rp.Id = ANY(SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
    WHERE 
        us.ReputationScore > 50
)
SELECT 
    pp.Title,
    pp.Score AS PopularityScore,
    pp.ViewCount,
    pp.CreationDate,
    u.DisplayName,
    CASE 
        WHEN pp.ReputationScore IS NULL THEN 'No Votes'
        ELSE pp.ReputationScore::varchar
    END AS ReputationStatus
FROM 
    PopularPosts pp
LEFT JOIN 
    Users u ON pp.OwnerUserId = u.Id
ORDER BY 
    pp.Score DESC, 
    pp.ViewCount ASC;

WITH PreviousCloseReasons AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastCloseDate 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(pcr.LastCloseDate, 'No closes yet') AS LastClose
FROM 
    Posts p
LEFT JOIN 
    PreviousCloseReasons pcr ON p.Id = pcr.PostId
WHERE 
    p.PostTypeId = 1 AND 
    (p.Score > 20 OR p.ViewCount > 100)
ORDER BY 
    p.Title;
