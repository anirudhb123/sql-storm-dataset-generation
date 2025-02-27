WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
), RecursivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        0 AS Level
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 -- top posts

    UNION ALL
    
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        rp.Level + 1
    FROM 
        RecursivePosts r
    JOIN 
        Posts p ON r.PostId = p.AcceptedAnswerId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    CASE 
        WHEN rp.Level > 0 THEN 'Follow-up Post'
        ELSE 'Top Question'
    END AS PostType,
    COALESCE(ph.RevisionGUID, 'No history') AS PostHistoryGUID,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.ExcerptPostId = p.Id 
     WHERE p.Id = rp.PostId) AS Tags
FROM 
    RecursivePosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
WHERE 
    rp.Score >= (SELECT AVG(Score) FROM Posts)
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
LIMIT 10;
