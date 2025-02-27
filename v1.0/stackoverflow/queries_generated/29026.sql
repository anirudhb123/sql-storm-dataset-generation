WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body, 
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Only consider upvotes
        JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
RecentUserPosts AS (
    SELECT 
        OwnerDisplayName,
        PostId,
        Title,
        CreationDate,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1  -- Select the most recent post for each user
)
SELECT 
    R.OwnerDisplayName, 
    R.Title,
    R.CreationDate,
    R.CommentCount,
    R.VoteCount,
    COALESCE(TEXT_AGG(DISTINCT t.TagName, ', ') FILTER (WHERE t.TagName IS NOT NULL), 'No Tags') AS Tags
FROM 
    RecentUserPosts R
LEFT JOIN 
    LATERAL (SELECT 
                  unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS TagName 
              FROM 
                  Posts p 
              WHERE 
                  p.Id = R.PostId) t ON TRUE
GROUP BY 
    R.OwnerDisplayName, R.Title, R.CreationDate, R.CommentCount, R.VoteCount
ORDER BY 
    R.VoteCount DESC, R.CommentCount DESC
LIMIT 10;
