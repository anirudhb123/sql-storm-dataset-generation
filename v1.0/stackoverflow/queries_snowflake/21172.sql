
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')  
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON TO_NUMBER(ph.Comment) = cr.Id  
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
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag.VALUE
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
        COALESCE(cpr.CloseReasons, ARRAY_CONSTRUCT()) AS CloseReasons,
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
    ARRAY_TO_STRING(ARRAY_FILTER(TPW.CloseReasons, x -> x IS NOT NULL), ';') AS CloseReasonSnippet,
    CASE 
        WHEN TPW.Score IS NULL THEN 'No Score'
        ELSE TO_VARCHAR(TPW.Score)
    END AS ScoreText
FROM 
    TopPostsWithReasons TPW
WHERE 
    TPW.TagCount > 3  
ORDER BY 
    TPW.Score DESC, 
    TPW.CreationDate DESC
LIMIT 100;
