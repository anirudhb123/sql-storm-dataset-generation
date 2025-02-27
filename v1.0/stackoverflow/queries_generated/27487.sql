WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS MostRecentCommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON true
    GROUP BY 
        p.Id
),
SelectedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 0
        AND rp.AnswerCount >= 2
        AND rp.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    sp.Title,
    sp.CreationDate,
    sp.Body,
    sp.ViewCount,
    sp.AnswerCount,
    sp.CommentCount,
    sp.Tags
FROM 
    SelectedPosts sp
ORDER BY 
    sp.ViewCount DESC, 
    sp.CreationDate ASC
LIMIT 10;
