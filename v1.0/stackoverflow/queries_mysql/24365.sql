
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
        AND p.Score IS NOT NULL
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        Rank,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.UpVoteCount,
    tp.DownVoteCount,
    CASE 
        WHEN tp.Score > 0 THEN 'Active' 
        WHEN tp.Score IS NULL THEN 'No score'
        ELSE 'Not Active' 
    END AS PostStatus,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = tp.PostId AND c.UserId IS NOT NULL) AS CommentCount,
    (SELECT GROUP_CONCAT(tag.TagName SEPARATOR ', ') 
     FROM Tags tag 
     INNER JOIN Posts p ON tag.ExcerptPostId = p.Id 
     WHERE p.Id = tp.PostId
    ) AS TagsList
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
WHERE 
    tp.UpVoteCount > 0 OR tp.DownVoteCount > 0
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10 OFFSET 0;
