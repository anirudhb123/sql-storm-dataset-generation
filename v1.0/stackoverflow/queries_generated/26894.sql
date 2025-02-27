WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
             p.Id AS PostId, 
             unnest(string_to_array(p.Tags, '>')) AS TagName 
         FROM 
             Posts p) t ON p.Id = t.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),

TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3
)

SELECT 
    trp.OwnerDisplayName,
    trp.Title,
    trp.CreationDate,
    trp.ViewCount,
    trp.Score,
    trp.CommentCount,
    STRING_AGG(t.TagName, ', ') AS AllTags,
    COUNT(v.Id) AS VoteCount,
    MAX(b.Date) AS LatestBadgeDate
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Votes v ON trp.PostId = v.PostId
LEFT JOIN 
    Badges b ON trp.OwnerDisplayName = b.UserId
GROUP BY 
    trp.OwnerDisplayName, trp.Title, trp.CreationDate, trp.ViewCount, trp.Score, trp.CommentCount
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
