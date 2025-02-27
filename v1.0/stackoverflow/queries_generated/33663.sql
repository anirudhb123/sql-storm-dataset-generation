WITH RecursiveTags AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired
    FROM Tags
    WHERE IsRequired = 1
    UNION ALL
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired
    FROM Tags t
    INNER JOIN RecursiveTags rt ON t.Count > rt.Count
),
PostsInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5) -- Considering only title and body edits
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, u.DisplayName
),
TagPostCounts AS (
    SELECT 
        pt.Id AS PostId,
        COUNT(DISTINCT pt.TagName) AS TagCount
    FROM PostLinks pl
    INNER JOIN Posts p ON pl.PostId = p.Id
    INNER JOIN Tags t ON pl.RelatedPostId = t.Id
    GROUP BY pt.Id
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.ViewCount,
    pi.Score,
    pi.OwnerDisplayName,
    pi.CommentCount,
    pi.EditCount,
    pi.VoteCount,
    COALESCE(tpc.TagCount, 0) AS TagCount,
    CASE 
        WHEN pi.Score >= 10 THEN 'Highly Rated'
        WHEN pi.Score BETWEEN 5 AND 9 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS Rating,
    STRING_AGG(DISTINCT rt.TagName, ', ') AS RequiredTags
FROM PostsInfo pi
LEFT JOIN TagPostCounts tpc ON pi.PostId = tpc.PostId
LEFT JOIN RecursiveTags rt ON rt.Id = pi.PostId
WHERE pi.ViewCount > 1000 -- Only considering posts with more than 1000 views
GROUP BY pi.PostId, pi.Title, pi.CreationDate, pi.ViewCount, pi.Score, pi.OwnerDisplayName, pi.CommentCount, pi.EditCount, pi.VoteCount, tpc.TagCount
ORDER BY pi.Score DESC, pi.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
