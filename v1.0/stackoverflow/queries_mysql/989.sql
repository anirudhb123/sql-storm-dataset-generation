
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.ViewCount DESC) AS Rank,
        CASE
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Pending'
        END AS AnswerStatus
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),

ClosedPostDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS CloseDate, 
        c.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON JSON_UNQUOTE(JSON_EXTRACT(ph.Comment, '$.reason')) IS NOT NULL
    WHERE 
        ph.PostHistoryTypeId = 10
)

SELECT 
    r.Title, 
    r.OwnerName, 
    r.CreationDate, 
    r.ViewCount, 
    r.AnswerStatus, 
    p.CloseDate, 
    p.CloseReason
FROM 
    RankedPosts r
LEFT JOIN 
    ClosedPostDetails p ON r.Id = p.PostId
WHERE 
    r.Rank <= 5
    OR (p.CloseDate IS NOT NULL AND r.CreationDate < p.CloseDate)
ORDER BY 
    r.Rank;
