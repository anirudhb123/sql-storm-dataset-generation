WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC, COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        rp.*, 
        u.DisplayName AS OwnerDisplayName
    FROM RankedPosts rp
    JOIN Users u ON rp.OwnerUserId = u.Id
    WHERE rp.Rank <= 5
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    t.OwnerDisplayName
FROM TopPosts t
ORDER BY t.UpVotes DESC, t.CommentCount DESC;
