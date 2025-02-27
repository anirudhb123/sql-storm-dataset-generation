WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        AVG(coalesced_avg_vote_up) OVER (PARTITION BY p.PostTypeId) AS AvgUpVotes,
        AVG(coalesced_avg_vote_down) OVER (PARTITION BY p.PostTypeId) AS AvgDownVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, 
               COALESCE(SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS coalesced_avg_vote_up,
               COALESCE(SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS coalesced_avg_vote_down
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

, PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::INT = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankByScore,
    pr.CloseReasons,
    CASE 
        WHEN rp.Score > 0 THEN 'Popular'
        WHEN rp.Score < 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS PopularityStatus,
    CONCAT_WS(' - ', u.DisplayName, COALESCE(u.Location, 'Location not provided')) AS UserInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostCloseReasons pr ON rp.PostId = pr.PostId
WHERE 
    rp.RankByScore <= 5
    AND (rp.AvgUpVotes - rp.AvgDownVotes) > 2
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate ASC
LIMIT 10;

-- The query performs the following complex operations:
-- 1. A Common Table Expression (CTE) to rank posts by score within their respective types.
-- 2. Aggregate the close reasons for posts from the PostHistory table.
-- 3. A classification using CASE statements for content popularity.
-- 4. String manipulation for displaying user information.
-- 5. It handles NULL cases effectively and uses advanced filtering and ranking logic.
