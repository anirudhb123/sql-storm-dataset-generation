WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(pc.Count, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        (SELECT COUNT(DISTINCT Comment.Id)
         FROM Comments Comment
         WHERE Comment.PostId = p.Id) AS TotalComments,
        (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) 
         FROM Votes v 
         WHERE v.PostId = p.Id) AS UpvoteCount,
        (SELECT SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) 
         FROM Votes v 
         WHERE v.PostId = p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS Count
         FROM 
            Comments 
         GROUP BY 
            PostId) pc ON pc.PostId = p.Id
    LEFT JOIN 
        (SELECT 
            Votes.PostId,
            SUM(CASE WHEN Votes.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN Votes.VoteTypeId IN (1, 4) THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes
         GROUP BY 
            Votes.PostId) v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpvoteCount > rp.DownvoteCount THEN 'Positive'
        WHEN rp.UpvoteCount < rp.DownvoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    PHT.Name AS LastPostHistoryType,
    ARRAY_AGG(DISTINCT Tags.TagName) AS RelatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON ph.PostId = rp.PostId 
LEFT JOIN 
    PostHistoryTypes PHT ON PHT.Id = ph.PostHistoryTypeId
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(rp.Tags, '><')) AS TagName) AS Tags ON TRUE
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, rp.UpVotes, rp.DownVotes, PHT.Name
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY
HAVING 
    COUNT(DISTINCT Tags.TagName) >= 2 OR (COALESCE(rp.CommentCount, 0) > 5 AND MAX(ph.CreationDate) > NOW() - INTERVAL '30 days')
;
