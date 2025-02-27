WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') -- Questions from the last year
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoreCount,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasonCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReasonCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.QuestionCount,
        us.PositiveScoreCount,
        us.NegativeScoreCount,
        cr.CloseReasonCount,
        cr.LastCloseDate,
        COUNT(DISTINCT rp.PostId) AS TopPostsRanked
    FROM 
        UserStats us
    LEFT JOIN 
        CloseReasonCounts cr ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cr.PostId LIMIT 1)
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.PostId
    GROUP BY 
        us.UserId, us.Reputation, us.QuestionCount, us.PositiveScoreCount, us.NegativeScoreCount, cr.CloseReasonCount, cr.LastCloseDate
)
SELECT 
    UserId,
    Reputation,
    QuestionCount,
    PositiveScoreCount,
    NegativeScoreCount,
    COALESCE(CloseReasonCount, 0) AS CloseReasonCount,
    LastCloseDate,
    COALESCE(TopPostsRanked, 0) AS TopPostsRanked
FROM 
    FinalStats
WHERE 
    Reputation > 100 -- Filter for users with a reputation greater than 100
ORDER BY 
    Reputation DESC, QuestionCount DESC, PositiveScoreCount DESC
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY; -- Paginate results, skipping the first 10
