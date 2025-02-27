WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName, Id) AS t ON p.Id = t.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        r.*,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = r.PostId AND v.VoteTypeId = 3) 
            THEN 'Has Downvotes' 
            ELSE 'No Downvotes' 
        END AS DownvoteStatus
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.TagList,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownvoteStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.OwnerUserId = u.Id 
WHERE 
    (fp.Score > 10 OR fp.CommentCount > 5) 
    AND u.Reputation >= 100
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 10;

SELECT 
    DISTINCT p.Id,
    t.TagName,
    ph.CreationDate,
    CASE 
        WHEN t.IsRequired THEN 'Required' 
        ELSE 'Optional' 
    END AS TagRequirement
FROM 
    Tags t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId = 4
    AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id AND PostHistoryTypeId = 4);
