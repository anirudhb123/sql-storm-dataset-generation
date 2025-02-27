
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        UP.Rank AS UserRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankWithinType,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            Id,
            CASE 
                WHEN Reputation >= 10000 THEN 'Elite'
                WHEN Reputation >= 1000 THEN 'Pro'
                ELSE 'Newbie' 
            END AS Rank
        FROM 
            Users
    ) UP ON u.Id = UP.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, UP.Rank
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
),
TopUpVotedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive scored'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative scored'
            ELSE 'Equally scored'
        END AS VoteAnalysis
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 'Elite' OR (rp.UserRank IS NULL AND rp.UpVoteCount > 5)
)

SELECT 
    t.Title,
    t.Score,
    t.UpVoteCount,
    t.DownVoteCount,
    t.VoteAnalysis,
    ph.HistoryType,
    ph.HistoryDate,
    ph.UserDisplayName,
    COALESCE(NULLIF(ph.Text, ''), 'No comment provided') AS HistoryComment
FROM 
    TopUpVotedPosts t
LEFT JOIN 
    PostHistoryDetails ph ON t.PostId = ph.PostId AND ph.HistoryRank <= 3
WHERE 
    (ph.HistoryDate IS NULL OR ph.HistoryDate >= DATEADD(day, -30, '2024-10-01'))
ORDER BY 
    t.Score DESC, 
    t.UpVoteCount DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM TopUpVotedPosts) / 2
;