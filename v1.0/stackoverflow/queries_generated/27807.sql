WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- We are only interested in questions
),
TaggedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        ARRAY_AGG(DISTINCT TRIM(UNNEST(string_to_array(rp.Tags, '>')))) AS UniqueTags,
        rp.Score,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Limit to top 5 questions per tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Score, rp.CreationDate
),
PostInfo AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.UniqueTags,
        tp.Score,
        tp.CreationDate,
        u.DisplayName AS Creator,
        COUNT(c.Id) AS CommentCount
    FROM 
        TaggedPosts tp
    LEFT JOIN 
        Users u ON tp.PostId = u.Id -- Join to get creator details
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId -- Counting comments
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.UniqueTags, tp.Score, tp.CreationDate, u.DisplayName
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.Body,
    pi.UniqueTags,
    pi.Score,
    pi.CreationDate,
    pi.Creator,
    pi.CommentCount,
    COALESCE(ARRAY_AGG(b.Name ORDER BY b.Date DESC), '{}'::varchar[]) AS BadgesEarned
FROM 
    PostInfo pi
LEFT JOIN 
    Badges b ON pi.Creator = b.UserId
WHERE 
    pi.Score > 10 -- Only questions with significant score
GROUP BY 
    pi.PostId, pi.Title, pi.Body, pi.UniqueTags, pi.Score, pi.CreationDate, pi.Creator, pi.CommentCount
ORDER BY 
    pi.Score DESC, pi.CreationDate DESC;
