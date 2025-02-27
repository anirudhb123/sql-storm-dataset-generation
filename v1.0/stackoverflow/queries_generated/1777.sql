WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Edit Body
    WHERE 
        p.Score > 10 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
), AggregateData AS (
    SELECT 
        PostId, 
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    ad.CommentCount,
    ad.TotalBounty,
    (CASE 
         WHEN ad.CommentCount > 10 THEN 'Hot Post'
         WHEN ad.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Active'
         ELSE 'Less Active'
     END) AS ActivityLevel,
    CONCAT('Posted by ', rp.OwnerDisplayName, ' on ', TO_CHAR(rp.CreationDate, 'YYYY-MM-DD')) AS PostDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregateData ad ON rp.PostId = ad.PostId
WHERE 
    rp.rn <= 5 -- Limit to top 5 posts per post type
ORDER BY 
    rp.Score DESC, ad.CommentCount DESC
LIMIT 50;
