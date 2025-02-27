WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS Tag(t) ON TRUE
    WHERE 
        p.PostTypeId = 1 AND -- Considering only Questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts created in the last year
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
)
SELECT 
    trp.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    SUM(vs.VoteCount) AS Upvotes,
    AVG(trp.Score) AS AverageScore,
    STRING_AGG(DISTINCT trp.TagName, ', ') AS Tags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Comments c ON trp.Id = c.PostId
LEFT JOIN 
    (
        SELECT 
            v.PostId,
            COUNT(v.Id) AS VoteCount
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2 -- Upvotes
        GROUP BY 
            v.PostId
    ) vs ON trp.Id = vs.PostId
GROUP BY 
    trp.OwnerDisplayName
ORDER BY 
    AverageScore DESC
LIMIT 10;
