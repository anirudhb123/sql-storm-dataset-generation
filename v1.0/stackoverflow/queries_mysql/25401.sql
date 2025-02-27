
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        @row_number := IF(@prev_tag = p.Tags, @row_number + 1, 1) AS Rank,
        @prev_tag := p.Tags
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @prev_tag := '') AS vars
    WHERE p.PostTypeId = 1 
    ORDER BY p.Tags, p.ViewCount DESC
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM RankedPosts rp
    WHERE rp.Rank <= 5 
),
PostInteraction AS (
    SELECT
        fp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM FilteredPosts fp
    LEFT JOIN Comments c ON fp.PostId = c.PostId
    LEFT JOIN Votes v ON fp.PostId = v.PostId
    GROUP BY fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, fp.ViewCount, fp.Score, fp.Tags
)
SELECT
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.Tags,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    (pi.UpVoteCount - pi.DownVoteCount) AS NetVotes
FROM FilteredPosts fp
JOIN PostInteraction pi ON fp.PostId = pi.PostId
ORDER BY fp.Score DESC, fp.CreationDate DESC;
