WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        SUM(v.VoteTypeId = 2) AS Upvotes,  -- Count only UpVotes
        SUM(v.VoteTypeId = 3) AS Downvotes, -- Count only DownVotes
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CreationDate
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Upvotes,
        rp.Downvotes,
        COALESCE(NULLIF(ROUND((rp.Upvotes::float / NULLIF((rp.Upvotes + rp.Downvotes), 0)) * 100, 2), 0), 0) AS UpvotePercentage,
        rp.Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, ','))::int)  -- Assuming Tags are stored as comma-separated IDs
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    WHERE 
        rp.Rank <= 5  -- Get Top 5 posts per PostTypeId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, rp.Upvotes, rp.Downvotes, rp.Rank
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.Upvotes,
    pd.Downvotes,
    pd.UpvotePercentage,
    pd.Rank,
    pd.Tags,
    pd.CommentCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Rank, pd.Upvotes DESC;
