
WITH TagCounts AS (
    SELECT
        TRIM(REGEXP_SUBSTR(Tags, '[^><]+', 1, seq)) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts,
    TABLE(GENERATOR(ROWCOUNT => 100)) AS seq
    WHERE PostTypeId = 1 
      AND seq <= REGEXP_COUNT(Tags, '><') + 1
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
    JOIN TopTags tt ON tt.TagName IN (SELECT TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq)) 
                                       FROM TABLE(GENERATOR(ROWCOUNT => 100)) AS seq
                                       WHERE seq <= REGEXP_COUNT(p.Tags, '><') + 1)
    WHERE tt.Rank <= 10 
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        LISTAGG(pc.Text, '; ') AS CommentTexts
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
