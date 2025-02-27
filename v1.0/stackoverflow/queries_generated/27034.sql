WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.LastActivityDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 -- Select top 5 ranked posts for each tag
)

SELECT 
    up.DisplayName AS Author,
    fp.Title,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.CommentCount,
    string_agg(tag.TagName, ', ') AS Tags,
    COUNT(ph.Id) AS HistoryCount,
    ARRAY_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReasons
FROM 
    FilteredPosts fp
JOIN 
    Users up ON fp.OwnerUserId = up.Id
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
LEFT JOIN 
    CloseReasonTypes cr ON ph.Comment::int = cr.Id AND ph.PostHistoryTypeId = 10
GROUP BY 
    up.DisplayName, fp.PostId, fp.Title, fp.CreationDate, fp.LastActivityDate, fp.CommentCount
ORDER BY 
    fp.CommentCount DESC
LIMIT 
    100; -- Limit to 100 results for performance
