
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name SEPARATOR ', ') AS CloseReasonNames,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostLinksInfo AS (
    SELECT 
        pl.PostId,
        COUNT(*) AS RelatedPosts,
        GROUP_CONCAT(DISTINCT p.Title SEPARATOR '; ') AS RelatedPostTitles
    FROM 
        PostLinks pl
    JOIN 
        Posts p ON pl.RelatedPostId = p.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    up.UserId,
    up.Reputation,
    up.TotalScore,
    up.PostCount,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    pr.CloseReasonNames,
    COALESCE(pr.CloseCount, 0) AS CloseCount,
    pli.RelatedPosts,
    pli.RelatedPostTitles,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.Rank < 5 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    UserScores up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    CloseReasons pr ON rp.PostId = pr.PostId
LEFT JOIN 
    PostLinksInfo pli ON rp.PostId = pli.PostId
WHERE 
    up.Reputation >= 100 AND 
    (up.TotalScore >= (SELECT MAX(TotalScore) FROM UserScores) OR up.PostCount > 5)
ORDER BY 
    up.TotalScore DESC, rp.ViewCount DESC;
