WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        u.Reputation AS AuthorReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 -- Filtering for Questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts created in the last year
),
PostComments AS (
    SELECT
        pc.PostId,
        COUNT(pc.Id) AS CommentCount,
        STRING_AGG(pc.Text, '; ') AS CommentTexts
    FROM
        Comments pc
    GROUP BY
        pc.PostId
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ph.Text
    FROM
        PostHistory ph
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12) -- Filtering for close, reopen, or delete actions
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.Author,
    rp.AuthorReputation,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pc.CommentTexts, 'No Comments') AS CommentSamples,
    MAX(pdh.CreationDate) AS LastPostHistoryDate,
    STRING_AGG(DISTINCT pdh.UserDisplayName, ', ') AS UsersInHistory,
    COUNT(DISTINCT pdh.PostHistoryTypeId) AS UniqueHistoryActions
FROM
    RankedPosts rp
LEFT JOIN
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN
    PostHistoryDetails pdh ON rp.PostId = pdh.PostId
WHERE
    rp.TagRank <= 5 -- Get only top 5 ranked post per tag
GROUP BY
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.Score,
    rp.Author,
    rp.AuthorReputation
ORDER BY
    rp.CreationDate DESC
LIMIT 100; -- Limit the number of returned rows
