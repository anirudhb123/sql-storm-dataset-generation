
;WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, CAST('2024-10-01 12:34:56' AS DATETIME))
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId) AS RevisionCount
FROM 
    RecentPosts rp
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
