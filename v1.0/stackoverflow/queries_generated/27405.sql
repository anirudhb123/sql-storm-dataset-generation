WITH UpdatedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM
        Posts p
    LEFT JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int[]
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.PostTypeId = 1 -- Questions only
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
PostHistoryStats AS (
    SELECT
        postId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PostHistoryTypeId IN (4, 5) THEN 1 END) AS TitleEdits,
        COUNT(CASE WHEN PostHistoryTypeId = 6 THEN 1 END) AS TagEdits,
        MAX(CreationDate) AS LastEditDate
    FROM
        PostHistory
    GROUP BY
        postId
),
FinalBenchmark AS (
    SELECT
        up.PostId,
        up.Title,
        up.CreationDate,
        up.Score,
        up.ViewCount,
        up.AcceptedAnswerId,
        up.Tags,
        up.CommentCount,
        up.VoteCount,
        up.UpVoteCount,
        up.DownVoteCount,
        phs.EditCount,
        phs.TitleEdits,
        phs.TagEdits,
        phs.LastEditDate
    FROM
        UpdatedPosts up
    LEFT JOIN
        PostHistoryStats phs ON phs.postId = up.PostId
)
SELECT
    fb.PostId,
    fb.Title,
    fb.CreationDate,
    fb.Score,
    fb.ViewCount,
    fb.AcceptedAnswerId,
    fb.Tags,
    fb.CommentCount,
    fb.VoteCount,
    fb.UpVoteCount,
    fb.DownVoteCount,
    fb.EditCount,
    fb.TitleEdits,
    fb.TagEdits,
    fb.LastEditDate,
    RANK() OVER (ORDER BY fb.Score DESC, fb.ViewCount DESC) AS RankScore,
    DENSE_RANK() OVER (ORDER BY fb.EditCount DESC) AS RankEdits
FROM
    FinalBenchmark fb
ORDER BY
    fb.RankScore, fb.RankEdits;
