WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed and Reopened
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        us.TotalPosts,
        us.PositivePosts,
        us.NegativePosts,
        us.AverageBounty,
        rp.PostTitle,
        rp.PostRank,
        cr.CloseReasonNames
    FROM 
        UserStats us
    JOIN 
        Users u ON us.UserId = u.Id
    LEFT JOIN 
        (SELECT PostId, Title AS PostTitle, PostRank FROM RankedPosts WHERE PostRank = 1) rp ON us.UserId = rp.OwnerUserId
    LEFT JOIN 
        CloseReasons cr ON rp.PostId = cr.PostId
)
SELECT 
    UserId,
    DisplayName,
    COALESCE(TotalPosts, 0) AS TotalPosts,
    COALESCE(PositivePosts, 0) AS PositivePosts,
    COALESCE(NegativePosts, 0) AS NegativePosts,
    COALESCE(AverageBounty, 0) AS AverageBounty,
    COALESCE(PostTitle, 'No Posts') AS MostValuablePost,
    COALESCE(PostRank, 'No Rank') AS PostRank,
    COALESCE(CloseReasonNames, 'Not Closed') AS CloseReasonNames
FROM 
    FinalResults
WHERE 
    TotalPosts > 5
ORDER BY 
    TotalPosts DESC, PositivePosts DESC
LIMIT 50;

-- This query showcases:
-- 1. CTEs for modular calculations breaking down posts, user statistics, and close reasons.
-- 2. Window functions for post ranking per user.
-- 3. Outer joins for comprehensive user statistics and close reasons.
-- 4. Use of aggregate functions combined with string functions to gather close reason information.
-- 5. COALESCE to handle NULL values gracefully across various columns.
