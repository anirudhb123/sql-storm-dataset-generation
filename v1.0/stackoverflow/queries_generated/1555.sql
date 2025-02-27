WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN pr.Name END) AS CloseReason,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes pr ON ph.Comment::int = pr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only consider close and reopen events
    GROUP BY 
        ph.PostId
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    cr.CloseReason,
    mu.DisplayName AS ActiveUser,
    mu.PostCount,
    mu.UpVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.Id = cr.PostId
RIGHT JOIN 
    MostActiveUsers mu ON rp.OwnerUserId = mu.UserId
WHERE 
    (cr.LastClosed IS NULL OR cr.LastClosed >= NOW() - INTERVAL '6 months')
    AND mu.PostCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC
LIMIT 100;
