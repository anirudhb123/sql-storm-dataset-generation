WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- UpVotes and DownVotes
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    COALESCE(vt.Name, 'Unknown Vote Type') AS VoteType,
    rp.VoteCount,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        WHEN rp.VoteCount > 5 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    ARRAY(
        SELECT 
            DISTINCT t.TagName 
        FROM 
            Posts pp
        CROSS JOIN 
            unnest(string_to_array(pp.Tags, '><')) AS t(TagName)
        WHERE 
            pp.Id = rp.PostId
    ) AS AssociatedTags
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteTypes vt ON vt.Id = (
        SELECT 
            v.VoteTypeId 
        FROM 
            Votes v 
        WHERE 
            v.PostId = rp.PostId 
        ORDER BY 
            v.CreationDate DESC 
        LIMIT 1
    )
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.Rank, rp.Score DESC
OFFSET (SELECT COUNT(*) FROM RankedPosts) / 2 ROWS
FETCH NEXT 5 ROWS ONLY;

-- Additionally, let's get a summary of closed posts and their reason
SELECT 
    p.Id AS ClosedPostId,
    p.Title,
    ph.CreationDate AS CloseDate,
    crt.Name AS CloseReason 
FROM 
    Posts p 
INNER JOIN 
    PostHistory ph ON p.Id = ph.PostId 
INNER JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id 
WHERE 
    ph.PostHistoryTypeId = 10 
    AND EXISTS (
        SELECT 1 
        FROM Posts pp 
        WHERE pp.AcceptedAnswerId = p.Id
    )
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;

-- Combine results using UNION ALL but only if both queries return non-empty results
SELECT * FROM (
    -- First query
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        Rank,
        VoteType,
        VoteCount,
        CommentCount,
        PostCategory,
        AssociatedTags
    FROM (
        -- Original query
    ) AS Derived1
    WHERE EXISTS (SELECT 1 FROM RankedPosts) 

    UNION ALL 

    -- Second query
    SELECT 
        ClosedPostId AS PostId,
        Title,
        NULL AS Score,
        NULL AS ViewCount,
        NULL AS Rank,
        NULL AS VoteType,
        NULL AS VoteCount,
        NULL AS CommentCount,
        NULL AS PostCategory,
        NULL AS AssociatedTags
    FROM (
        -- Closed posts query
    ) AS Derived2
    WHERE EXISTS (SELECT 1 FROM Posts WHERE ph.PostHistoryTypeId = 10)
) FinalResults;
