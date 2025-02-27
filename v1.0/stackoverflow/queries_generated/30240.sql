WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Initial close and reopen actions
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON ph.Id = rph.Id
)

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS AuthorDisplayName,
    ph.PostTypeId,
    COUNT(DISTINCT v.Id) AS VoteCount,
    COALESCE(rph.CloseCount, 0) AS CloseCount,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' 
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened' 
        ELSE 'Active' 
    END AS PostStatus,
    STRING_AGG(t.TagName, ', ') AS Tags,
    SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
    SUM(COALESCE(b.Class, 0)) AS BadgeCount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId
LEFT JOIN 
    RecursivePostHistory rph ON p.Id = rph.PostId
LEFT JOIN 
    Comments c ON c.PostId = p.Id
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts created in the last year
    AND (p.Title LIKE '%SQL%' OR p.Body LIKE '%query%')
GROUP BY 
    p.Id, u.DisplayName, p.Title, p.CreationDate, ph.PostTypeId
ORDER BY 
    VoteCount DESC, CloseCount DESC, PostCreationDate DESC

OPTION (MAXRECURSION 100);
