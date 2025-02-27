WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(ph.Id) FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation > 1000 ORDER BY p.CreationDate DESC) AS Ranking
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1  -- Questions only
        AND p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.VoteCount,
        rp.CommentCount,
        rp.CloseReopenCount
    FROM
        RankedPosts rp
    WHERE
        rp.Ranking <= 10  -- Select top 10 most recent posts by users with Reputation above 1000
)
SELECT
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.VoteCount,
    fp.CommentCount,
    fp.CloseReopenCount,
    COALESCE(STRING_AGG(DISTINCT t.TagName, ', '), 'No Tags') AS AssociatedTags
FROM
    FilteredPosts fp
LEFT JOIN
    Posts p ON fp.PostId = p.Id
LEFT JOIN
    UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '> <'))::text[]) AS tagIds(tag) ON TRUE
LEFT JOIN
    Tags t ON t.TagName = TRIM(tagIds.tag)
GROUP BY
    fp.PostId, fp.Title, fp.Body, fp.CreationDate, fp.OwnerDisplayName, fp.VoteCount, fp.CommentCount, fp.CloseReopenCount
ORDER BY
    fp.VoteCount DESC, fp.CreationDate DESC
LIMIT 20;
