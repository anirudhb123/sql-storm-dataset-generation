
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
        AND p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR))
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT CONCAT_WS(' - ', ctr.Name, CAST(ph.CreationDate AS CHAR)) ORDER BY ph.CreationDate ASC SEPARATOR '; ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS UNSIGNED) = ctr.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
TopRankedPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Author,
        cr.CloseCount,
        cr.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cr ON rp.PostID = cr.PostId
    WHERE 
        rp.Rank <= 5
        AND (cr.CloseCount IS NULL OR cr.CloseCount < 3) 
)
SELECT 
    TRIM(BOTH ' ' FROM TRIM(LEADING '0' FROM TRIM(BOTH '-' FROM (CASE 
        WHEN Score IS NOT NULL THEN CAST((Score * 100) / NULLIF(ViewCount, 0) AS CHAR)
        ELSE '0'
    END)))) AS Score_Percentage,
    CONCAT('Title: ', Title, ' | Author: ', Author, ' | Views: ', ViewCount, ' | Score: ', Score, 
           ' | Close Count: ', COALESCE(CloseCount, 0), ' | Close Reasons: ', COALESCE(CloseReasons, 'None')) AS PostDetails
FROM 
    TopRankedPosts
ORDER BY 
    Score DESC;
