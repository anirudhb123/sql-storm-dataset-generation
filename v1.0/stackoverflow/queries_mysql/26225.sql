
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts 
    JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
          UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
),
PostsWithTopTags AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        tt.TagName,
        tt.PostCount
    FROM Posts p
    JOIN TopTags tt ON FIND_IN_SET(tt.TagName, SUBSTRING(TRIM(BOTH '{}' FROM p.Tags), 2, LENGTH(TRIM(BOTH '{}' FROM p.Tags)) - 2)) > 0
    WHERE tt.Rank <= 10 
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        GROUP_CONCAT(pc.Text SEPARATOR '; ') AS CommentTexts
    FROM Comments pc
    GROUP BY pc.PostId
),
PostWithComments AS (
    SELECT
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.TagName,
        p.PostCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.CommentTexts, '') AS CommentTexts
    FROM PostsWithTopTags p
    LEFT JOIN PostComments pc ON p.PostId = pc.PostId
)
SELECT
    p.PostId,
    p.Title,
    p.CreationDate,
    p.TagName,
    p.PostCount,
    p.CommentCount,
    p.CommentTexts,
    CASE 
        WHEN p.CommentCount > 10 THEN 'Highly Engaged'
        WHEN p.CommentCount >= 1 AND p.CommentCount <= 10 THEN 'Moderately Engaged'
        ELSE 'Minimal Engagement'
    END AS EngagementLevel
FROM PostWithComments p
ORDER BY p.PostCount DESC, p.CreationDate DESC;
