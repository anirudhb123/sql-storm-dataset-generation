WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        p.PostTypeId,
        p.AcceptedAnswerId,
        COALESCE(
            (SELECT COUNT(*) 
             FROM Comments c 
             WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE(
            (SELECT SUM(v.BountyAmount) 
             FROM Votes v 
             WHERE v.PostId = p.Id
             AND v.VoteTypeId IN (8, 9)), 0) AS TotalBounty
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.TotalBounty,
    CASE 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL AND rp.PostTypeId = 1 THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = rp.OwnerUserId
WHERE 
    rp.Rank = 1
    AND (rp.CommentCount > 5 OR rp.TotalBounty > 0)
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC;

-- Additionally, examining the posts with a complicated join to related posts
WITH RelatedPosts AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkTypeName
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    COUNT(DISTINCT r.RelatedPostId) AS NumOfRelatedPosts,
    ARRAY_AGG(DISTINCT r.LinkTypeName) AS LinkTypes
FROM 
    RankedPosts rp
LEFT JOIN 
    RelatedPosts r ON rp.PostId = r.PostId
GROUP BY 
    rp.PostId, rp.Title
HAVING 
    COUNT(DISTINCT r.RelatedPostId) > 2
ORDER BY 
    rp.Score DESC;
