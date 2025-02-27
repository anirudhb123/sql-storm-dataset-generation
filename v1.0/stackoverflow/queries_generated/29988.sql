WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Only Upvotes and Downvotes
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS tagName ON tagName IS NOT NULL
    LEFT JOIN 
        Tags t ON tagName = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerName,
        u.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerName,
    tp.Reputation,
    tp.ViewCount,
    tp.CommentCount,
    tp.LastActivityDate,
    STRING_AGG(DISTINCT tag.TagName, ', ') AS AllTags
FROM 
    TopPosts tp
LEFT JOIN 
    unnest(tp.Tags) AS tag ON tag IS NOT NULL
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerName, tp.Reputation, tp.ViewCount, tp.CommentCount, tp.LastActivityDate
ORDER BY 
    tp.ViewCount DESC;
