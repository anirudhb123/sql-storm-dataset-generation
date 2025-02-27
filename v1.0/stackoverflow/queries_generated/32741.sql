WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1  -- Only questions
        AND p.Score >= 0  -- Only non-negative scores
),
RecentPosts AS (
    SELECT
        p.PostId,
        p.Title,
        p.OwnerDisplayName,
        ph.CreationDate AS LastEditDate,
        ph.UserId AS EditedByUserId,
        ph.Comment AS EditComment,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerDisplayName ORDER BY ph.CreationDate DESC) AS EditRank
    FROM
        RankedPosts p
    JOIN
        PostHistory ph ON p.PostId = ph.PostId
    WHERE
        ph.PostHistoryTypeId IN (4, 5)  -- Edit Title or Body
)
SELECT
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate AS QuestionDate,
    COALESCE(rp.LastEditDate, 'N/A') AS LastEditDate,
    CASE
        WHEN rp.EditRank = 1 THEN 'Most Recent Edit'
        ELSE 'Earlier Edit'
    END AS EditStatus,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes
FROM
    RankedPosts rp
LEFT JOIN
    Comments c ON rp.PostId = c.PostId
LEFT JOIN
    Votes v ON rp.PostId = v.PostId
WHERE
    rp.rn = 1  -- Only the latest question per user
GROUP BY
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.LastEditDate, rp.EditRank
ORDER BY
    rp.CreationDate DESC;
