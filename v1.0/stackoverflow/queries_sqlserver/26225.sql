
WITH TagCounts AS (
    SELECT
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts,
    STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE PostTypeId = 1 
    GROUP BY value
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
    JOIN TopTags tt ON tt.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
    WHERE tt.Rank <= 10 
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        STRING_AGG(pc.Text, '; ') AS CommentTexts
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
