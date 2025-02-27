WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 6) THEN 'Closed'
            ELSE 'Active'
        END AS Status,
        COALESCE((SELECT MAX(ph.CreationDate) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)), p.CreationDate) AS LastChangeDate
    FROM 
        Posts p
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.AcceptedAnswerId,
    rp.Score,
    rp.ViewCount,
    rp.PostRank,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.Status,
    rp.LastChangeDate,
    CASE 
        WHEN rp.Score > 100 THEN 'Hot'
        WHEN rp.ViewCount > 1000 THEN 'Trending'
        ELSE 'Normal'
    END AS PostCategory,
    STRING_AGG(t.TagName, ', ') AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    PostsTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
WHERE 
    rp.Status = 'Active' 
    AND rp.LastChangeDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.AcceptedAnswerId, rp.Score, rp.ViewCount, rp.PostRank, rp.UpVoteCount, rp.DownVoteCount, rp.Status, rp.LastChangeDate
HAVING 
    (COUNT(t.TagName) > 3 OR rp.Score > 50)
ORDER BY 
    rp.Score DESC, rp.LastChangeDate ASC;

-- Additional Outer Join on Comments for Posts with no comments
LEFT JOIN (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
) AS comment_summary ON rp.PostId = comment_summary.PostId
WHERE 
    comment_summary.CommentCount IS NULL
OR 
    comment_summary.CommentCount < 5

