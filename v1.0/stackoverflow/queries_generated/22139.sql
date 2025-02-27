WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP) AND 
        p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        MAX(ph.UserDisplayName) AS ClosedBy,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
),
BadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        CASE 
            WHEN SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) > 0 THEN 'Gold'
            WHEN SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) > 0 THEN 'Silver'
            ELSE 'Bronze or No Badges'
        END AS BadgeStatus
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        cp.CloseDate,
        cp.ClosedBy,
        cp.CloseReasons,
        bu.BadgeCount,
        bu.BadgeStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        BadgedUsers bu ON rp.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.ScoreRank <= 5
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    COALESCE(fr.Score, 0) AS FinalScore,
    COALESCE(fr.CommentCount, 0) AS TotalComments,
    fr.CloseDate,
    fr.ClosedBy,
    COALESCE(fr.CloseReasons, 'Open Post') AS CloseReasons,
    COALESCE(fr.BadgeCount, 0) AS UserBadgeCount,
    fr.BadgeStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.CreationDate DESC, 
    fr.FinalScore DESC;

-- This query aims to analyze high-scoring posts from the last year, showing those that were closed, along with user badge information.
-- Nuanced logic ensures that posts without comments or scores are treated appropriately, and NULL handling is implemented throughout.
