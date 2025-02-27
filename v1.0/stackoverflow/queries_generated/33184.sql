WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.Reputation AS OwnerReputation,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_name)
    GROUP BY 
        p.Id
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerReputation,
    COALESCE(CP.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(CP.CloseReason, 'N/A') AS CloseReason,
    PT.Tags
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.Id = CP.PostId AND CP.CloseRank = 1
LEFT JOIN 
    PostTags PT ON RP.Id = PT.PostId
WHERE 
    RP.PostRank = 1
ORDER BY 
    RP.OwnerReputation DESC, 
    RP.Score DESC
LIMIT 100;
