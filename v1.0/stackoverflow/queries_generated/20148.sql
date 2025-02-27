WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        *,
        CASE 
            WHEN Rank = 1 THEN 'Top Post'
            WHEN Rank <= 5 THEN 'Hot Post'
            ELSE 'Regular Post'
        END AS Classification
    FROM 
        RankedPosts
)
SELECT 
    tp.Classification,
    tp.Title,
    tp.Score,
    tp.UpvoteCount - tp.DownvoteCount AS NetScore,
    STRING_AGG(t.TagName, ', ') AS TagsList,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(b.Class), 0) AS BadgeClassifications
FROM 
    TopPosts tp
OUTER JOIN 
    Tags t ON t.Id = ANY(STRING_TO_ARRAY(tp.Tags, '><')::int[])
INNER JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Date >= NOW() - INTERVAL '1 year'
WHERE 
    (u.Reputation IS NOT NULL AND u.Reputation > 0) 
    OR (u.Location IS NULL AND u.CreationDate <= NOW() - INTERVAL '5 years')
GROUP BY 
    tp.Classification, tp.Title, tp.Score, tp.UpvoteCount, tp.DownvoteCount, u.DisplayName
HAVING 
    COUNT(c.Id) > (SELECT COUNT(*) FROM Comments cm WHERE cm.PostId = tp.PostId) / 2
ORDER BY 
    NetScore DESC, tp.Score DESC
LIMIT 100;
