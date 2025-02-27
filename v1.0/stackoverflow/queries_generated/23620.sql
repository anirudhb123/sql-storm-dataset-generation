WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecencyRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes,
        COUNT(c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
),
PostChurn AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
),
FinalMetrics AS (
    SELECT 
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ue.UserId,
        ue.TotalUpvotes,
        ue.TotalDownvotes,
        ue.TotalComments,
        pc.UserId AS LastEditor,
        COUNT(DISTINCT CASE WHEN pc.PostHistoryTypeId = 10 THEN pc.UserId END) AS TotalClosures,
        COUNT(CASE WHEN pc.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopens
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserEngagement ue ON ue.UserId = rp.PostId
    LEFT JOIN 
        PostChurn pc ON pc.PostId = rp.PostId AND pc.HistoryRank = 1
    GROUP BY 
        rp.Title, rp.CreationDate, rp.Score, ue.UserId, ue.TotalUpvotes, ue.TotalDownvotes, pc.UserId
)
SELECT 
    fm.Title,
    fm.CreationDate,
    fm.Score,
    fm.TotalUpvotes,
    fm.TotalDownvotes,
    fm.TotalComments,
    fm.LastEditor,
    fm.TotalClosures,
    fm.TotalReopens,
    CASE 
        WHEN fm.TotalUpvotes IS NULL THEN 0
        ELSE fm.TotalUpvotes
    END AS NonNullUpvotes,
    CASE 
        WHEN fm.TotalComments > 100 THEN 'Highly Engaged'
        WHEN fm.TotalComments BETWEEN 50 AND 100 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    FinalMetrics fm
WHERE 
    fm.Score > 5
ORDER BY 
    fm.Score DESC, fm.CreationDate DESC
LIMIT 50;
