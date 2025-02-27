WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        U.Reputation AS UserReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users U ON rp.UserPostRank = 1 AND U.Id = p.OwnerUserId
)
SELECT 
    ps.*,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = ps.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
FROM 
    PostStatistics ps
WHERE 
    ps.ViewCount > 1000
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
