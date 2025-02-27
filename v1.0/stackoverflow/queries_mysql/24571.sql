
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
UserVoteDetails AS (
    SELECT 
        v.PostId, 
        v.UserId, 
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE vt.Name IN ('UpMod', 'DownMod')
    GROUP BY v.PostId, v.UserId, vt.Name
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate,
        GROUP_CONCAT(DISTINCT ph.Comment ORDER BY ph.Comment SEPARATOR ', ') AS Comments
    FROM PostHistory ph
    WHERE ph.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 5 YEAR
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    rp.CreationDate,
    rp.Rank,
    ud.UserId,
    ud.VoteType,
    ud.VoteCount,
    COALESCE(phd.HistoryCount, 0) AS HistoryCount,
    phd.LastChangeDate,
    phd.Comments
FROM RankedPosts rp
LEFT JOIN UserVoteDetails ud ON rp.PostId = ud.PostId
LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank <= 3
    AND (ud.VoteType IS NULL OR ud.VoteType = 'UpMod')
ORDER BY rp.CreationDate DESC, rp.Score DESC;
