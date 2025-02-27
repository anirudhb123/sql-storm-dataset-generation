WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        p.OwnerUserId,
        u.Reputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopens,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletesUndeletes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.Rank,
        pha.CloseReopens,
        pha.DeletesUndeletes,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryAggregates pha ON rp.PostId = pha.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8
    WHERE 
        rp.Rank <= 5  -- Top 5 posts by score for each post type
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount, rp.Score, rp.CreationDate, rp.Rank, pha.CloseReopens, pha.DeletesUndeletes
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(p.Score, 0)) > 50
),
FinalResults AS (
    SELECT 
        cd.PostId,
        cd.Title,
        cd.ViewCount,
        cd.Score,
        cd.CreationDate,
        cu.UserId,
        cu.DisplayName,
        cu.TotalScore,
        cd.CloseReopens,
        cd.DeletesUndeletes,
        cd.TotalBounty
    FROM 
        CombinedData cd
    LEFT JOIN 
        PopularUsers cu ON cd.OwnerUserId = cu.UserId
)

SELECT 
    *,
    CASE 
        WHEN TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus,
    COALESCE(NULLIF(ViewCount, 0), 1) AS EffectiveViewCount,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - CreationDate)) AS AgeInSeconds
FROM 
    FinalResults
ORDER BY 
    Score DESC, Views DESC;
