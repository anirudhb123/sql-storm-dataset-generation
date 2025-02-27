WITH TagStatistics AS (
    SELECT 
        LOWER(TRIM(t.TagName)) AS NormalizedTag,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount,
        ARRAY_AGG(DISTINCT u.DisplayName) AS UsersContributed
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Users u ON u.Id = p.OwnerUserId
    GROUP BY NormalizedTag
),
TopTags AS (
    SELECT 
        NormalizedTag,
        PostCount,
        CommentCount,
        UpvoteCount,
        DownvoteCount,
        UsersContributed,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagStatistics
)
SELECT 
    t.NormalizedTag,
    t.PostCount,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    t.UsersContributed,
    COALESCE(ROUND(100.0 * t.UpvoteCount / NULLIF(t.UpvoteCount + t.DownvoteCount, 0), 2), 0) AS UpvoteRatio
FROM TopTags t
WHERE t.Rank <= 10
ORDER BY t.UpvoteCount DESC;
