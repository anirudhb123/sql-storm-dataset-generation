WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.ViewCount
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < (NOW() - INTERVAL '6 months')
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rs.DisplayName AS OwnerName,
        rs.Reputation,
        ph.CloseDate,
        ph.ReopenDate,
        ph.CloseReopenCount,
        ph.CloseReasons,
        rp.CommentCount,
        COALESCE(NULLIF(rp.ViewCount, 0), 1) AS AdjustedViewCount  -- Handle potential NULL/zero view counts
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics rs ON rp.OwnerUserId = rs.UserId
    LEFT JOIN 
        PostHistoryAnalysis ph ON rp.PostId = ph.PostId
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rs.Reputation DESC, 
        rp.CreationDate DESC
)

SELECT 
    *,
    CASE 
        WHEN CloseReopenCount > 0 THEN 'Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus,
    ROUND(AdjustedViewCount::numeric / NULLIF(CommentCount, 0), 2) AS ViewToCommentRatio
FROM 
    FinalReport
WHERE 
    Reputation > 1000
    OR poststatus = 'Closed/Reopened'
ORDER BY 
    PostStatus, 
    AdjustedViewCount DESC;
