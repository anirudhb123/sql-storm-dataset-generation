WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Views,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(NULLIF(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)), 0), NULL) AS ActivityDuration
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100 AND
        p.CreationDate >= NOW() - INTERVAL '365 days'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ClosureCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
    GROUP BY 
        ph.PostId
),
FinalPostData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Views,
        us.AvgReputation,
        cp.ClosureCount,
        cp.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserStatistics us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        ClosedPosts cp ON cp.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5 -- limit results to top 5 posts per type
)
SELECT 
    f.Title,
    f.Score,
    f.Views,
    COALESCE(f.AvgReputation, 0) AS AvgReputation,
    COALESCE(f.ClosureCount, 0) AS ClosureCount,
    COALESCE(f.CloseReasons, 'No closure reasons') AS ClosureReasons,
    CASE 
        WHEN f.ClosureCount IS NULL THEN 'Active'
        WHEN f.ClosureCount < 3 THEN 'Potentially contestable'
        ELSE 'Closed frequently'
    END AS PostStatus
FROM 
    FinalPostData f
ORDER BY 
    f.Score DESC, f.Views DESC;
