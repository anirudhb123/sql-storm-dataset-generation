WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(t.TagName) AS TagsArray,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, u.DisplayName
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.TagsArray,
        CASE 
            WHEN rp.ViewRank <= 10 THEN 'Top Viewed'
            ELSE 'Other'
        END AS ViewCategory,
        CASE 
            WHEN rp.ScoreRank <= 10 THEN 'Top Scored'
            ELSE 'Other'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.ViewCount,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.TagsArray,
    pd.ViewCategory,
    pd.ScoreCategory,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount, -- Count only Upvotes
    COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount -- Count only Downvotes
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.Body, pd.ViewCount, pd.CreationDate, pd.Score, pd.OwnerDisplayName, pd.TagsArray, pd.ViewCategory, pd.ScoreCategory
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
