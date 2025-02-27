WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only consider questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) -- Higher than average score
        AND COALESCE(p.ClosedDate, false) = false -- Not closed posts
),

RankedPosts AS (
    SELECT 
        fp.*,
        RANK() OVER (ORDER BY fp.Score DESC, fp.ViewCount DESC) AS RankScore
    FROM 
        FilteredPosts fp
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.OwnerDisplayName,
        rp.TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 100 -- Top 100 based on score and views
)

SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.TagCount,
    (SELECT string_agg(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.TagName IN (
         SELECT unnest(string_to_array(substring(tp.Tags, 2, length(tp.Tags)-2), '><'))
     )) AS Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
