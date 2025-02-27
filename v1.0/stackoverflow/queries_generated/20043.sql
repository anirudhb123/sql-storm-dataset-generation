WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(c.UserDisplayName, 'Anonymous') AS AuthorName,
        p.Tags,
        CASE 
            WHEN p.ViewCount IS NULL THEN 'No Views'
            WHEN p.ViewCount < 50 THEN 'Few Views'
            WHEN p.ViewCount BETWEEN 50 AND 200 THEN 'Moderate Views'
            ELSE 'Many Views'
        END AS ViewCategory
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),

TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 10
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.AuthorName,
    rp.ViewCategory,
    tt.TagName,
    tt.TagCount,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
    COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
FROM RankedPosts rp
LEFT JOIN Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
LEFT JOIN Votes v ON rp.PostId = v.PostId
JOIN TopTags tt ON tt.TagName = t.TagName
WHERE rp.Rank <= 5 
AND (rp.Score > 0 OR rp.ViewCategory = 'Many Views') 
GROUP BY rp.PostId, rp.Title, rp.Score, rp.CreationDate, rp.AuthorName, tt.TagName, tt.TagCount
HAVING COUNT(DISTINCT v.Id) > 0
ORDER BY rp.CreationDate DESC, rp.Score DESC;

-- Additional convoluted edge case logic
SELECT 
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN 1 END) > 0 THEN 'Has Upvotes'
        WHEN COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN 1 END) > 0 THEN 'Has Downvotes'
        ELSE 'No Votes'
    END AS VoteStatus,
    string_agg(DISTINCT rp.AuthorName, ', ') AS Authors
FROM RankedPosts rp
LEFT JOIN Votes v ON rp.PostId = v.PostId
GROUP BY rp.PostId
HAVING MAX(rp.CreationDate) IS NOT NULL
AND COUNT(DISTINCT rp.TagName) > 1;
