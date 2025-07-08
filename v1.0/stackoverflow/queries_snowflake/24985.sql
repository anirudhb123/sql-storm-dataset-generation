
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
),
PopularTags AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(input => STRING_SPLIT(p.Tags, '><')) AS tag
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::TIMESTAMP)
    GROUP BY 
        TRIM(tag)
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        LISTAGG(DISTINCT crt.Name, ', ') WITHIN GROUP (ORDER BY crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
    HAVING 
        COUNT(*) > 1 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    pt.TagCount,
    cp.CloseReasonCount,
    COALESCE(cp.CloseReasons, 'No reasons') AS CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(rp.Title, ' '))) 
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC;
