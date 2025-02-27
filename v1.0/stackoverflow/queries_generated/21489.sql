WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    GROUP BY 
        u.Id
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenVotes,
        COUNT(ph.Id) AS TotalHistoryEntries
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

StatsWithRanks AS (
    SELECT 
        ups.*,
        phs.CloseVotes,
        phs.ReopenVotes,
        phs.TotalHistoryEntries,
        RANK() OVER (ORDER BY ups.TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY ups.TotalBounty DESC) AS BountyRank
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryStats phs ON phs.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId)
)

SELECT 
    s.DisplayName,
    s.TotalPosts,
    s.TotalAnswers,
    s.AcceptedAnswers,
    s.TotalBounty,
    s.CloseVotes,
    s.ReopenVotes,
    s.TotalHistoryEntries,
    CASE 
        WHEN TotalPosts = 0 THEN NULL 
        ELSE ROUND((TotalAnswers::decimal / TotalPosts) * 100, 2) 
    END AS AnswerRate,
    CASE 
        WHEN AcceptedAnswers = 0 THEN NULL 
        ELSE ROUND((AcceptedAnswers::decimal / TotalAnswers) * 100, 2) 
    END AS AcceptedRate,
    CASE 
        WHEN PostRank IS NULL THEN 'Unranked' 
        ELSE PostRank::TEXT 
    END AS PostRank,
    CASE 
        WHEN BountyRank IS NULL THEN 'Unranked' 
        ELSE BountyRank::TEXT 
    END AS BountyRank
FROM 
    StatsWithRanks s
WHERE 
    (s.TotalPosts > 5 OR s.TotalBounty > 0)
    AND (s.ReopenVotes > 0 OR s.CloseVotes > 0)
ORDER BY 
    s.PostRank, s.BountyRank, s.DisplayName;
