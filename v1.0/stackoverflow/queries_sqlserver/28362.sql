
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year' 
), CloseStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonsCount,
        STRING_AGG(crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INT) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
), TopTags AS (
    SELECT 
        value AS TagName
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    WHERE 
        TagRank = 1 
)
SELECT 
    rp.Title AS QuestionTitle,
    rp.Author,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    ct.CloseReasonsCount,
    ct.CloseReasons,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseStats ct ON rp.PostId = ct.PostId
JOIN 
    TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, ','))
WHERE 
    rp.TagRank = 1
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
