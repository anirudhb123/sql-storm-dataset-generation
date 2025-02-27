WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  -- Consider only Questions and Answers
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Filter for the past year
),
FilteredPosts AS (
    SELECT 
        Posts.PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        Posts.RankScore,
        array_length(string_to_array(Posts.Tags, '>'), 1) AS TagCount
    FROM 
        RankedPosts Posts
    WHERE 
        RankScore <= 10  -- Top 10 posts by score and view count per type
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.TagCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    STRING_AGG(DISTINCT bt.Name, ', ') AS BadgesEarned
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
LEFT JOIN 
    Badges b ON b.UserId = fp.OwnerId
LEFT JOIN 
    PostHistory ph ON ph.PostId = fp.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
LEFT JOIN 
    Badges bt ON bt.UserId = fp.OwnerUserId  -- Optional: Join to badges
WHERE 
    ph.CreationDate BETWEEN fp.CreationDate AND CURRENT_TIMESTAMP
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.Score, fp.ViewCount, fp.TagCount
ORDER BY 
    fp.ViewCount DESC, fp.Score DESC;
