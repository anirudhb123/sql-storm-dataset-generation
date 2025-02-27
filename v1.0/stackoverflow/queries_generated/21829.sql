WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.ViewCount IS NOT NULL AND 
        p.Score IS NOT NULL
),
PostsWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.OwnerDisplayName = b.UserId
    WHERE 
        rp.ScoreRank <= 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PostAnalytics AS (
    SELECT 
        pwb.PostId,
        pwb.Title,
        pwb.CreationDate,
        pwb.Score,
        pwb.ViewCount,
        pwb.Tags,
        pwb.OwnerDisplayName,
        pwb.BadgeName,
        phs.EditorCount,
        phs.LastEditDate,
        phs.CloseReopenCount,
        CASE 
            WHEN phs.CloseReopenCount > 0 THEN 'Closed/Reopened' 
            ELSE 'Active' 
        END AS PostStatus,
        CONCAT('Total Views: ', COALESCE(CAST(pwb.ViewCount AS VARCHAR), '0')) AS ViewDetails
    FROM 
        PostsWithBadges pwb
    JOIN 
        PostHistorySummary phs ON pwb.PostId = phs.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.Score,
    pa.ViewCount,
    pa.Tags,
    pa.OwnerDisplayName,
    pa.BadgeName,
    pa.EditorCount,
    pa.LastEditDate,
    pa.PostStatus,
    pa.ViewDetails
FROM 
    PostAnalytics pa
WHERE 
    pa.Score >= (SELECT AVG(Score) FROM Posts)
ORDER BY 
    pa.Score DESC, 
    pa.CreationDate ASC
LIMIT 100;
