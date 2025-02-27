WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentTotal,
        COALESCE(SUM(vote.VoteTypeId = 2) - SUM(vote.VoteTypeId = 3), 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentTotal,
    rp.NetVotes,
    cp.CloseRank,
    cp.CloseReason,
    us.DisplayName AS TopBountyUser,
    us.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRank = 1
JOIN 
    UserStats us ON rp.PostId IN (
        SELECT PostId 
        FROM Votes 
        WHERE VoteTypeId IN (8) 
        GROUP BY PostId 
        ORDER BY SUM(BountyAmount) DESC 
        LIMIT 1
    )
WHERE 
    rp.RankScore <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
