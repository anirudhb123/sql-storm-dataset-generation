WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.ViewCount > 100
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(V.Score) AS AverageVotingScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes V ON p.Id = V.PostId AND V.VoteTypeId = 2 -- Upvotes
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS RevisionCount,
        MAX(ph.CreationDate) AS LastRevisionDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.AcceptedAnswers,
    us.AverageVotingScore,
    rp.Title AS MostRecentPostTitle,
    rps.CreationDate AS MostRecentPostDate,
    phs.RevisionCount,
    phs.LastRevisionDate,
    phs.HistoryTypes,
    COALESCE(NULLIF(it.UserId, 0), 'N/A') AS LastInteractionUser
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostHistorySummary phs ON rp.Id = phs.PostId
LEFT JOIN 
    (SELECT DISTINCT ph.UserId, ph.PostId
     FROM PostHistory ph
     WHERE ph.UserId IS NOT NULL) it ON it.PostId = rp.Id
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.TotalPosts DESC, us.AverageVotingScore DESC;
