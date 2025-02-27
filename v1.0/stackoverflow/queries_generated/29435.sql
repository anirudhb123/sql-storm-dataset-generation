WITH TagFrequency AS (
    SELECT
        UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  -- Only questions
    GROUP BY
        Tag
),
TopTags AS (
    SELECT
        Tag,
        TagCount
    FROM
        TagFrequency
    ORDER BY
        TagCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.Tag) AS AssociatedTags
    FROM
        Posts p
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        TagFrequency t ON t.Tag = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))
    WHERE
        p.PostTypeId = 1  -- Only questions
    GROUP BY
        p.Id, b.Name
)
SELECT
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.BadgeName,
    ps.CommentCount,
    ps.VoteCount,
    ARRAY_AGG(DISTINCT tt.Tag) FILTER (WHERE tt.Tag IS NOT NULL) AS TopTags
FROM
    PostStatistics ps
LEFT JOIN
    TopTags tt ON tt.Tag = ANY(ps.AssociatedTags)
GROUP BY
    ps.PostId, ps.Title, ps.Score, ps.ViewCount, ps.BadgeName, ps.CommentCount, ps.VoteCount
ORDER BY
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
