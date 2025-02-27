WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    AND 
        p.Score > 0
),
ClosingReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalBounty,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    COALESCE(c.CloseReasons, 'No close reasons') AS CloseReasons,
    (u.Upvotes - u.Downvotes) AS NetVotes,
    (u.Reputation + COALESCE(u.TotalBounty, 0)) AS FinalScore
FROM 
    UserScore u
LEFT JOIN 
    TopPosts tp ON u.UserId = tp.OwnerUserId AND tp.PostRank = 1
LEFT JOIN 
    ClosingReasons c ON tp.PostId = c.PostId
WHERE 
    (u.Reputation + COALESCE(u.TotalBounty, 0)) > 1000
ORDER BY 
    FinalScore DESC
LIMIT 10;
