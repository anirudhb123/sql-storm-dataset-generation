WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag,
        ARRAY_AGG(DISTINCT u.DisplayName) AS TopCommenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.TopCommenters
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTag <= 3 -- Top 3 posts per tag
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    fp.TopCommenters,
    STRING_AGG(DISTINCT ph.Comment, '; ') AS PostHistoryComments,
    STRING_AGG(DISTINCT ph.UserDisplayName || ' on ' || to_char(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS') || ': ' || ph.Text, '; ') AS HistoryDetails
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.Tags, fp.CreationDate, fp.Score, fp.CommentCount, fp.UpvoteCount, fp.DownvoteCount, fp.TopCommenters
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
