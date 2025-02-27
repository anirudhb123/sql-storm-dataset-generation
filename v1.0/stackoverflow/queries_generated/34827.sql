WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
), 
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(vb.BountyAmount), 0) AS TotalBountySpent
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId AND vb.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.QuestionCount,
    us.TotalBountySpent,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    phs.EditCount,
    phs.LastEdited,
    phs.PostHistoryTypes
FROM 
    UserScores us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    us.Reputation >= 100  -- Users with at least 100 reputation
    AND rp.UserPostRank = 1  -- Only the highest scoring question per user
ORDER BY 
    us.Reputation DESC,  
    rp.ViewCount DESC;  -- Order by reputation and then views
