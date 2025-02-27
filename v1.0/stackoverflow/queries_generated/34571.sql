WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 -- Questions only
),
RecentVotes AS (
    SELECT
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
TagsAggregate AS (
    SELECT
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    JOIN Tags tg ON tg.ExcerptPostId = p.Id OR tg.WikiPostId = p.Id
    GROUP BY p.Id
),
PostHistoryAggregate AS (
    SELECT
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenEvents
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.Author,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    ta.Tags,
    COALESCE(pha.LastEdited, 'No edits') AS LastEdited,
    pha.CloseReopenEvents
FROM RankedPosts rp
LEFT JOIN RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN TagsAggregate ta ON rp.PostId = ta.PostId
LEFT JOIN PostHistoryAggregate pha ON rp.PostId = pha.PostId
WHERE rp.PostRank = 1 -- Show only the most recent question per user
ORDER BY rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
