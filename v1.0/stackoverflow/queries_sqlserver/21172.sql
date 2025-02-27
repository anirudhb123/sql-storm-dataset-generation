
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.Score >= (SELECT AVG(Score) FROM Posts)  
      AND 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ',') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id  
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag ON 1=1 
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id
),
TopPostsWithReasons AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerReputation,
        COALESCE(cpr.CloseReasons, '') AS CloseReasons,
        pt.TagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPostReasons cpr ON rp.PostId = cpr.PostId
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    WHERE 
        rp.Rank = 1  
)
SELECT 
    TPW.PostId,
    TPW.Title,
    TPW.Score,
    TPW.CreationDate,
    TPW.OwnerReputation,
    TPW.CloseReasons,
    TPW.TagCount,
    CASE 
        WHEN TPW.OwnerReputation > 1000 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel,
    CONCAT(NULLIF(PARSENAME(REPLACE(TPW.CloseReasons, ',', '.'), 1), ''), 
           NULLIF(PARSENAME(REPLACE(TPW.CloseReasons, ',', '.'), 2), '')) AS CloseReasonSnippet,
    CASE 
        WHEN TPW.Score IS NULL THEN 'No Score'
        ELSE CAST(TPW.Score AS NVARCHAR)
    END AS ScoreText
FROM 
    TopPostsWithReasons TPW
WHERE 
    TPW.TagCount > 3  
ORDER BY 
    TPW.Score DESC, 
    TPW.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
