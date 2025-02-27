WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    JOIN Users U ON p.OwnerUserId = U.Id
    WHERE p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
PopularUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS Downvotes
    FROM Users U
    LEFT JOIN Posts p ON U.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY U.Id, U.DisplayName
    HAVING PostCount > 5
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS CloseDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT)
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.UserDisplayName, ph.CreationDate
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS INT), 0) AS Upvotes,
        COALESCE(CAST(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS INT), 0) AS Downvotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(c.AnswerCount, 0) AS AnswerCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (SELECT 
        PostId, 
        COUNT(CommentId) AS CommentCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN Id END) AS AnswerCount
        FROM Comments 
        GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, c.CommentCount, c.AnswerCount
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    pu.DisplayName AS PopularUserName,
    ps.Upvotes,
    ps.Downvotes,
    ch.CloseDate,
    ch.CloseReasons
FROM RecentPosts rp
LEFT JOIN PopularUsers pu ON rp.OwnerUserId = pu.UserId
LEFT JOIN PostStats ps ON rp.PostId = ps.Id
LEFT JOIN ClosedPostHistory ch ON rp.PostId = ch.PostId
WHERE rp.rn <= 5
ORDER BY rp.CreationDate DESC, rp.Score DESC;
