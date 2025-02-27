WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagsList,
        rp.RankByScore,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
    ORDER BY 
        rp.Score DESC
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.TagsList,
    fp.CommentCount,
    fp.UpvoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12)) AS VoteHistoryCount
FROM 
    FilteredPosts fp
INNER JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
WHERE 
    u.Reputation > 1000
ORDER BY 
    fp.CreationDate DESC;

This query benchmarks string processing by aggregating tags from the `Posts` table, evaluating user interactions through `Comments` and `Votes`, and filtering posts based on various criteria, such as score and user reputation. It organizes posts by their score and displays relevant metrics for the top posts from the past year.
