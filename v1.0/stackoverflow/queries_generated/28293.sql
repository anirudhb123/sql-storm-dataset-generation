WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount,
        string_agg(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    LEFT JOIN 
        (SELECT unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName, PostId FROM Posts) t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= now() - interval '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),

HighViewRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Score,
        OwnerDisplayName,
        Rank,
        VoteCount,
        TagList
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 AND ViewCount > 100
)

SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    p.Rank,
    p.VoteCount,
    CONCAT('Tags: ', p.TagList) AS Tags,
    CHAR_LENGTH(p.Body) AS BodyLength,
    LEAST(CHAR_LENGTH(p.Body), 500) AS ShortenedBody  -- Limiting body length for display
FROM 
    HighViewRankedPosts p
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 50;
