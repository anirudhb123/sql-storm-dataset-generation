WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.ANSWERCOUNT,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.Reputation AS UserReputation,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100
),
TopRankedPosts AS (
    SELECT 
        rp.*,
        (CASE 
            WHEN rp.UserReputation > 10000 THEN 'High' 
            WHEN rp.UserReputation BETWEEN 5000 AND 10000 THEN 'Medium' 
            ELSE 'Low' 
         END) AS ReputationLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)

SELECT 
    trp.PostID,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.ReputationLevel,
    COALESCE(trp.Upvotes, 0) AS Upvotes,
    COALESCE(trp.Downvotes, 0) AS Downvotes,
    CASE 
        WHEN trp.Upvotes - trp.Downvotes > 10 THEN 'Popular'
        WHEN trp.Upvotes - trp.Downvotes BETWEEN -10 AND 10 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS PopularityTag
FROM 
    TopRankedPosts trp
ORDER BY 
    trp.ReputationLevel DESC, trp.Score DESC;

-- Further exploration of post histories to see changes in popularity and user participation
SELECT 
    ph.PostId,
    ph.CreationDate,
    ph.PostHistoryTypeId,
    p.Title,
    CASE 
        WHEN ph.Comment IS NOT NULL THEN ph.Comment
        ELSE 'No Comment'
    END as EditComment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 10) -- Look for title edits, body edits, and post closures
ORDER BY 
    ph.CreationDate DESC
LIMIT 5;

-- Analyze the relationship of posts closed for being duplicates to their original posts
SELECT 
    pl.PostId AS DuplicatedPost,
    pl.RelatedPostId AS OriginalPost,
    COUNT(*) AS DuplicateCount
FROM 
    PostLinks pl
JOIN 
    Posts p ON pl.PostId = p.Id
WHERE 
    pl.LinkTypeId = 3 -- Duplicates
GROUP BY 
    pl.PostId, pl.RelatedPostId
HAVING 
    COUNT(*) > 1
ORDER BY 
    DuplicateCount DESC;
