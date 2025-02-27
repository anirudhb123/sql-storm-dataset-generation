WITH StringProcessingBenchmark AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        ph.UserDisplayName AS Editor,
        ph.CreationDate AS EditDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount,
        pg_size_pretty(pg_total_relation_size('Posts')) AS TotalPostSize
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[])
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for recent posts
    GROUP BY
        p.Id, ph.UserDisplayName, ph.CreationDate
    ORDER BY
        Upvotes DESC,
        EditDate DESC
    LIMIT 100
)
SELECT
    *,
    (Upvotes - Downvotes) AS NetVotes,
    CASE 
        WHEN TagCount = 0 THEN 'No Tags'
        WHEN TagCount < 3 THEN 'Few Tags'
        ELSE 'Many Tags'
    END AS TagDensity
FROM
    StringProcessingBenchmark
WHERE
    Editor IS NOT NULL
ORDER BY
    TagCount DESC, 
    NetVotes DESC;
