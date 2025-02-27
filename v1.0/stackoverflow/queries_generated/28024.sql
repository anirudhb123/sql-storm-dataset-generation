WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ViewCount,
        COALESCE(CAST(AVG(v.VoteTypeId = 2) AS FLOAT) * 100, 0) AS UpvotePercentage,
        COALESCE(CAST(AVG(v.VoteTypeId = 3) AS FLOAT) * 100, 0) AS DownvotePercentage,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.AcceptedAnswerId, p.ViewCount
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.AcceptedAnswerId,
        rp.ViewCount,
        rp.UpvotePercentage,
        rp.DownvotePercentage,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Badges b ON b.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.AcceptedAnswerId, rp.ViewCount, 
        rp.UpvotePercentage, rp.DownvotePercentage
),
StringProcessedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.CreationDate,
        pd.AcceptedAnswerId,
        pd.ViewCount,
        pd.UpvotePercentage,
        pd.DownvotePercentage,
        pd.CommentCount,
        pd.BadgeCount,
        ARRAY_LENGTH(string_to_array(pd.Body, ' '), 1) AS WordCount, -- Number of words in Body
        LEAST(pd.UpvotePercentage, pd.DownvotePercentage) AS MinVotePercentage   -- Min vote percentage for processing
    FROM 
        PostDetails pd
    WHERE 
        pd.WordCount > 100 -- Filter for posts with more than 100 words
)

SELECT 
    sp.PostId,
    sp.Title,
    sp.WordCount,
    sp.UpvotePercentage,
    sp.DownvotePercentage,
    sp.CommentCount,
    sp.BadgeCount,
    sp.MinVotePercentage
FROM 
    StringProcessedPosts sp
WHERE
    sp.MinVotePercentage < 20 -- Selecting posts with a minimum vote percentage of less than 20%
ORDER BY 
    sp.WordCount DESC, sp.UpvotePercentage DESC;
