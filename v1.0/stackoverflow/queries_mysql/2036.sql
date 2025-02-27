
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        @rank := IF(@prev_owner = p.OwnerUserId, @rank + 1, 1) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        @prev_owner := p.OwnerUserId
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @rank := 0, @prev_owner := NULL) r
    WHERE p.CreationDate >= '2023-10-01 12:34:56' AND p.PostTypeId = 1
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    pv.UpVotes,
    pv.DownVotes,
    pc.CommentCount,
    cp.FirstClosedDate,
    CASE 
        WHEN cp.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM RankedPosts rp
LEFT JOIN PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.Rank = 1
ORDER BY rp.CreationDate DESC
LIMIT 100;
