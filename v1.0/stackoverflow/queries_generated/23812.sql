WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId 
    WHERE p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
),

MostViewedPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostTypeName,
        u.DisplayName AS OwnerDisplayName
    FROM RankedPosts rp
    JOIN PostTypes pt ON rp.PostTypeId = pt.Id
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.ViewRank <= 5
),

TopComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        STRING_AGG(c.Text, '; ') AS CommentText
    FROM Comments c
    GROUP BY c.PostId
),

PostDetails AS (
    SELECT 
        mvp.*,
        tc.TotalComments,
        tc.CommentText
    FROM MostViewedPosts mvp
    LEFT JOIN TopComments tc ON mvp.PostId = tc.PostId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
)

SELECT 
    pd.PostId,
    pd.Title, 
    pd.ViewCount, 
    pd.AnswerCount,
    pd.PostTypeName,
    pd.OwnerDisplayName,
    COALESCE(cl.CloseCount, 0) AS NumberOfClosures,
    COALESCE(cl.LastClosedDate, '2023-01-01'::timestamp) AS MostRecentClosure,
    pd.TotalComments,
    pd.CommentText,
    CASE 
        WHEN cl.CloseCount > 0 THEN 'Post has been closed'
        ELSE 'Post is open'
    END AS PostClosureStatus,
    CASE 
        WHEN pd.ViewCount IS NULL THEN 'Unknown ViewCount'
        ELSE 'ViewCount available'
    END AS ViewCountStatus
FROM PostDetails pd
LEFT JOIN ClosedPosts cl ON pd.PostId = cl.PostId
ORDER BY pd.ViewCount DESC, pd.AnswerCount DESC
LIMIT 10;

