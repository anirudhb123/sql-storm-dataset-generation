
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= date_sub('2024-10-01', INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.PostTypeId
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        GROUP_CONCAT(DISTINCT ctr.Name ORDER BY ctr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), CombinedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Owner,
        rp.Rank,
        COALESCE(cp.FirstClosedDate, NULL) AS FirstClosedDate,
        COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReasons,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    *,
    CASE 
        WHEN Rank <= 5 THEN 'Top Ranking Post'
        WHEN CommentCount = 0 THEN 'No Comments Yet'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    CombinedResults
ORDER BY 
    Score DESC, CreationDate DESC;
