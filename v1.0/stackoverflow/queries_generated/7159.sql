WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(MAX(v.CreationDate) FILTER (WHERE v.VoteTypeId = 2), p.CreationDate) AS LastUpvoteDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC, rp.Score DESC) AS PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserScoreRank <= 5 -- Top 5 posts per user
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.CommentCount,
    fp.OwnerDisplayName,
    fp.LastUpvoteDate
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10 -- Top 10 posts overall
ORDER BY 
    fp.ViewCount DESC, 
    fp.Score DESC;
