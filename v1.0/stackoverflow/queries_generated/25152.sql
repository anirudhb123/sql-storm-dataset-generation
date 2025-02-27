WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.OwnerName,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank <= 5 -- Top 5 most recent questions per user
),
TagAggregated AS (
    SELECT
        p.PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        FilteredPosts p
    LEFT JOIN Posts p2 ON p.PostId = p2.Id
    LEFT JOIN LATERAL unnest(string_to_array(substring(p2.Tags, 2, length(p2.Tags) - 2), '><')) AS tagName ON TRUE
    LEFT JOIN Tags t ON t.TagName = tagName
    GROUP BY
        p.PostId
)
SELECT
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.OwnerName,
    fp.CommentCount,
    fp.Upvotes,
    fp.Downvotes,
    ta.Tags
FROM
    FilteredPosts fp
JOIN
    TagAggregated ta ON fp.PostId = ta.PostId
ORDER BY
    fp.CreationDate DESC;
