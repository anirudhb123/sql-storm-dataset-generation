WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    JOIN
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_array(tag) ON TRUE
    JOIN
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag_array.tag)
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY
        p.Id, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName,
        COUNT(*) AS TagUsage
    FROM
        Posts p
    JOIN
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_array(tag) ON TRUE
    JOIN
        Tags t ON t.TagName = TRIM(BOTH ' ' FROM tag_array.tag)
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY
        t.TagName
    HAVING
        COUNT(*) > 50 -- Only tags used in more than 50 posts
),
TopRankedPosts AS (
    SELECT
        rp.*,
        pt.TagUsage
    FROM
        RankedPosts rp
    LEFT JOIN
        PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, ', '))
    WHERE
        rp.PostRank <= 10
)
SELECT
    PostId,
    Title,
    ViewCount,
    Score,
    AnswerCount,
    Tags,
    Author,
    TagUsage
FROM
    TopRankedPosts
ORDER BY
    Score DESC, ViewCount DESC;
