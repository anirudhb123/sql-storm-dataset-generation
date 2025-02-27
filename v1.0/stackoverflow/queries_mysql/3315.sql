
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @rank := IF(@currentUserId = p.OwnerUserId, @rank + 1, 1) AS Rank,
        @currentUserId := p.OwnerUserId,
        COALESCE(up.UpVotes, 0) AS UpVotes,
        COALESCE(dn.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS up ON p.Id = up.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS dn ON p.Id = dn.PostId
    CROSS JOIN (SELECT @rank := 0, @currentUserId := NULL) AS vars
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT cr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        cp.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.UpVotes,
    fr.DownVotes,
    COALESCE(fr.CloseReasons, 'No Close Reasons') AS CloseReasons,
    (CASE WHEN fr.UpVotes > fr.DownVotes THEN 'Positive' ELSE 'Negative' END) AS Sentiment
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
