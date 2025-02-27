WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.TagCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL string_to_array(p.Tags, '<>') AS tagName ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagName
    GROUP BY 
        p.Id, u.DisplayName
),

TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        OwnerDisplayName,
        CommentCount,
        TagsList
    FROM 
        RankedPosts
    WHERE 
        RecentPostRank = 1
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.CommentCount,
    STRING_AGG(tag, ', ') AS ConcatenatedTags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    UNNEST(trp.TagsList) AS tag ON true
GROUP BY 
    trp.PostId, trp.Title, trp.Body, trp.CreationDate, trp.OwnerDisplayName, trp.CommentCount
ORDER BY 
    trp.CreationDate DESC
LIMIT 10;
