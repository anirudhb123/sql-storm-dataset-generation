WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        OwnerDisplayName,
        OwnerReputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    trp.*,
    pt.Name AS PostType,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostsTags pt ON trp.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
JOIN 
    PostHistory ph ON trp.PostId = ph.PostId
WHERE 
    ph.CreationDate >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 30 DAY) -- Posts edited in the last 30 days
GROUP BY 
    trp.PostId
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
