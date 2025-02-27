WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::jsonb @> jsonb_build_array(crt.Id)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)

SELECT 
    up.DisplayName,
    up.Reputation,
    io.RankScore,
    io.VoteCount,
    io.UpVoteCount,
    io.Title,
    io.Score,
    io.ViewCount,
    io.AnswerCount,
    cp.CloseReasons
FROM 
    RankedPosts io
JOIN 
    UserReputation up ON io.RankScore <= 5 AND up.UserId = io.Id
LEFT JOIN 
    ClosedPosts cp ON io.Id = cp.PostId
WHERE 
    io.ViewCount > 1000 
    AND (cp.CreationDate IS NULL OR cp.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days'))
ORDER BY 
    up.Reputation DESC, io.Score DESC
LIMIT 100;
