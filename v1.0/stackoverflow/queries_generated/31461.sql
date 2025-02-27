WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Interested in posts that were closed, reopened, or deleted
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(UPT.TotalVotes, 0) AS TotalVotes,
        COALESCE(CAST(SUM(v.BountyAmount) AS INT), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(pb.CreationDate) AS LastEdited
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) AS UPT ON p.Id = UPT.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        RecursivePostHistory ph
    GROUP BY 
        ph.PostId
),
PostScore AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score + COALESCE(cp.CloseCount, 0) * 10 AS AdjustedScore -- Award 10 points for each close as a deduction mechanism
    FROM 
        PostDetails pd
    LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.AdjustedScore,
    pd.ViewCount,
    pd.CommentCount,
    pd.BadgeCount,
    ROW_NUMBER() OVER (ORDER BY ps.AdjustedScore DESC) AS Rank
FROM 
    PostScore ps
JOIN 
    PostDetails pd ON ps.PostId = pd.PostId
WHERE 
    pd.TotalVotes > 0
ORDER BY 
    ps.AdjustedScore DESC, pd.ViewCount DESC
LIMIT 100;
