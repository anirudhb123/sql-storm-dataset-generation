WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        (SELECT COUNT(DISTINCT c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    rp.CommentCount,
    (SELECT STRING_AGG(DISTINCT b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = rp.OwnerUserId) AS OwnerBadges,
    (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
     FROM PostTypes pt 
     JOIN Posts p2 ON p2.PostTypeId = pt.Id 
     WHERE p2.ParentId = rp.PostId) AS RelatedPostTypes
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
