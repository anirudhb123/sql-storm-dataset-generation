WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        COALESCE(SUM(ph.UserId IS NOT NULL AND ph.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15)), 0) AS ClosureActionCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON p.Tags::text LIKE '%' || t.TagName || '%'::text
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND (p.AcceptedAnswerId IS NULL OR p.PostTypeId != 1) /* Exclude accepted answers */
    GROUP BY 
        p.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.VoteCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.ClosureActionCount > 0 THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.rn <= 10 /* Top 10 recent posts per type */
ORDER BY 
    rp.VoteCount DESC,
    rp.CreationDate DESC
LIMIT 100;

-- Additional testing with NULL and corner case conditions
SELECT
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts WHERE Id IS NULL) THEN 'At least one post with NULL Id exists'
        ELSE 'All posts have valid Ids'
    END AS PostValidation,
    COUNT(CASE WHEN p.Body IS NULL THEN 1 END) AS NullBodyCount
FROM 
    Posts p
WHERE 
    p.ViewCount IS NOT NULL OR (p.ViewCount IS NULL AND p.Id < 0);
