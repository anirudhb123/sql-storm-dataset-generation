WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Title IS NOT NULL
),
PostStatistics AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerReputation,
        Rank,
        CASE 
            WHEN AnswerCount = 0 THEN NULL 
            ELSE Score::float / AnswerCount 
        END AS ScorePerAnswer
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT c.Text, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        Comments c ON ph.Comment IS NOT NULL AND ph.Comment = CAST(c.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed, Reopened
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1 -- Only Gold badges
    GROUP BY 
        UserId
)
SELECT 
    ps.PostID,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.OwnerReputation,
    COALESCE(cp.LastClosedDate, 'No closures') AS LastClosedDate,
    COALESCE(cp.CloseReasons, 'No close reasons') AS CloseReasons,
    ub.BadgeCount AS GoldBadges,
    CASE 
        WHEN ps.ScorePerAnswer > 5 THEN 'High Performance'
        WHEN ps.ScorePerAnswer IS NULL THEN 'No Answers'
        ELSE 'Average Performance'
    END AS PerformanceRating
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostID = cp.PostId
LEFT JOIN 
    UserBadges ub ON ps.OwnerReputation = ub.UserId
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
LIMIT 20;
