WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(NULLIF(UPPER(p.Title), ''), 'Untitled') AS NormalizedTitle,
        STRING_AGG(DISTINCT SUBSTRING(t.TagName, 1, 10), ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')))
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 END) AS ReopenUndeleteCount,
        COUNT(ph.Id) AS TotalHistory
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.Rank,
    rp.NormalizedTitle,
    hp.CloseCount,
    hp.ReopenUndeleteCount,
    ue.DisplayName,
    ue.CommentCount,
    ue.TotalBounty,
    CASE 
        WHEN ue.CommentCount > 5 THEN 'Highly Engaged'
        WHEN ue.TotalBounty IS NOT NULL AND ue.TotalBounty > 0 THEN 'Bountier'
        ELSE 'Minimal Engagement'
    END AS EngagementStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated hp ON rp.PostId = hp.PostId
LEFT JOIN 
    UserEngagement ue ON rp.OwnerUserId = ue.UserId
WHERE 
    (rp.Score > 10 OR hp.CloseCount IS NULL) 
    AND (ue.CommentCount IS NOT NULL AND ue.TotalBounty IS NOT NULL)
ORDER BY 
    rp.Score DESC, hp.TotalHistory ASC, ue.CommentCount DESC;

