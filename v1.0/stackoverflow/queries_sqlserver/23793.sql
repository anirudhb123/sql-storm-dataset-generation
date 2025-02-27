
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS date) - DATEADD(YEAR, 1, 0) 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId, 
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS int) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
HighScoringQuestions AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerDisplayName,
        COALESCE(cr.CloseReasonNames, '') AS CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CloseReasons cr ON rp.PostId = cr.PostId
    WHERE 
        rp.Rank <= 5 
),
PostDetails AS (
    SELECT 
        hsq.*,
        (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
         FROM Tags t 
         WHERE t.ExcerptPostId = hsq.PostId) AS Tags
    FROM 
        HighScoringQuestions hsq
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.CloseReasons,
    pd.Tags,
    CASE 
        WHEN pd.CloseReasons != '' THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    DATEDIFF(HOUR, pd.CreationDate, CAST('2024-10-01 12:34:56' AS DATETIME)) AS AgeInHours
FROM 
    PostDetails pd
WHERE 
    (pd.CloseReasons = '' AND pd.Score >= 10 OR pd.CloseReasons != '')
ORDER BY 
    pd.Score DESC, AgeInHours ASC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
