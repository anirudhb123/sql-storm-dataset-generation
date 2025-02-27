
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id  
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
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT @row := @row + 1 AS n
               FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) AS numbers,
                    (SELECT @row := 0) AS r) numbers
         WHERE @row < CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tags ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag
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
    CONCAT_WS(';', NULLIF(SUBSTRING_INDEX(TPW.CloseReasons, ',', 1), ''), NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(TPW.CloseReasons, ',', 2), ',', -1), '')) AS CloseReasonSnippet,
    CASE 
        WHEN TPW.Score IS NULL THEN 'No Score'
        ELSE CAST(TPW.Score AS CHAR)
    END AS ScoreText
FROM 
    TopPostsWithReasons TPW
WHERE 
    TPW.TagCount > 3  
ORDER BY 
    TPW.Score DESC, 
    TPW.CreationDate DESC
LIMIT 100;
