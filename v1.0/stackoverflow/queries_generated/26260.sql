WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON TRUE 
    JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.AnswerCount > 0
)

SELECT 
    fp.Id,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.Tags,
    fp.Upvotes,
    fp.Downvotes,
    ROUND(COALESCE(fp.Upvotes::decimal / NULLIF(fp.Upvotes + fp.Downvotes, 0), 0), 2) AS UpvoteRatio
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10 -- Focus on top 10 posts
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
