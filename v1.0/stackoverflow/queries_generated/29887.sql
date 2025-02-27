WITH PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(SUBSTRING(t.TagName, 1, 20), ', ') AS Tags, 
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                STRING_AGG(t.TagName, ', ') AS TagName
            FROM 
                Tags t
            WHERE 
                t.Id IN (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, length(p.Tags)-2), '><'))::int)
        ) AS t ON TRUE
    GROUP BY 
        p.Id, u.DisplayName
), 
PostHistoryGroup AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS LastClosedReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    p.Body,
    p.Tags,
    p.OwnerDisplayName,
    p.CreationDate,
    ph.HistoryCount,
    ph.LastEditDate,
    ph.LastClosedReason,
    CASE
        WHEN p.AcceptedAnswerId > 0 THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus
FROM 
    PostWithTags p
JOIN 
    PostHistoryGroup ph ON p.PostId = ph.PostId
WHERE 
    p.ViewCount > 100
ORDER BY 
    ph.HistoryCount DESC, 
    p.CreationDate DESC
LIMIT 10;
