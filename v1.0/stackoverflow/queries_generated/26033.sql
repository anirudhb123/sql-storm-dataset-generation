WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerDisplayName, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY rp.VoteCount DESC, rp.CommentCount DESC) AS rn
    FROM 
        RankedPosts rp
    WHERE 
        rp.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts in the last year
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AcceptedAnswerId,
    fp.CommentCount,
    fp.VoteCount,
    fp.Tags
FROM 
    FilteredPosts fp
WHERE 
    fp.rn <= 10;  -- Top 10 posts based on votes and comments
