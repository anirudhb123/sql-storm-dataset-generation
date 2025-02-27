WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_arr ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_arr)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),

CommentedPosts AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId
),

PostScoreRankings AS (
    SELECT 
        rp.*,
        cp.CommentCount,
        RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewCountRank
    FROM 
        RankedPosts rp
    JOIN 
        CommentedPosts cp ON rp.PostId = cp.PostId
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    AnswerCount,
    Score,
    OwnerDisplayName,
    Tags,
    CommentCount,
    ScoreRank,
    ViewCountRank
FROM 
    PostScoreRankings
WHERE 
    ScoreRank <= 10  -- Top 10 posts by score
    OR ViewCountRank <= 10  -- Top 10 posts by views
ORDER BY 
    ScoreRank, ViewCountRank;
