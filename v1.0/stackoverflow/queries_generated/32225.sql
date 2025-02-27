WITH RECURSIVE Popularity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        pl.RelatedPostId,
        p.Title,
        p.Score + pl.LinkTypeId AS Score, -- Aggregate score with the LinkTypeId affecting the popularity
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community User'),
        p.CreationDate,
        Level + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        Posts p ON pl.PostId = p.Id
    INNER JOIN 
        Popularity pop ON pl.PostId = pop.PostId
)

SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.Score,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    (SELECT COUNT(*)
     FROM Badges b
     WHERE b.UserId = p.OwnerUserId AND b.Class = 1) AS GoldBadgeCount, 
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t
     JOIN STRING_TO_ARRAY(p.Tags, ',') tagnames ON t.TagName = TRIM(tagnames)
     WHERE t.IsModeratorOnly = 0) AS TagsList
FROM 
    Popularity p
LEFT JOIN 
    Comments c ON p.PostId = c.PostId
LEFT JOIN 
    Votes v ON p.PostId = v.PostId AND v.VoteTypeId IN (2, 3) -- only upvotes and downvotes
WHERE 
    p.Level = 1 -- Filter for initial popularity level only
GROUP BY 
    p.PostId, p.Title, p.OwnerDisplayName, p.CreationDate, p.Score
HAVING 
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) > 2 -- More than 2 upvotes
ORDER BY 
    p.Score DESC
LIMIT 10;
