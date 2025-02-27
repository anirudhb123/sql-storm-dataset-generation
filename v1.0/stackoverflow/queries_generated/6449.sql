WITH UserReputation AS (
    SELECT Id, Reputation
    FROM Users
    WHERE Reputation > 1000
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Questions
    AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, u.DisplayName
    HAVING COUNT(c.Id) > 5 -- More than 5 comments
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(CONCAT(ph.UserDisplayName, ': ', ph.Comment), '; ') AS EditComments
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY ph.PostId, p.Title
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    u.Reputation AS OwnerReputation,
    ph.LastEditDate,
    ph.EditComments
FROM TopPosts tp
INNER JOIN UserReputation u ON tp.OwnerDisplayName = u.DisplayName
LEFT JOIN PostHistoryDetails ph ON tp.PostId = ph.PostId
ORDER BY tp.Score DESC, tp.ViewCount DESC
LIMIT 50;
