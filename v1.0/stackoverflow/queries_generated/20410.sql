WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        (SELECT COUNT(DISTINCT b.Id) 
         FROM Badges b 
         WHERE b.UserId = p.OwnerUserId AND b.Class = 1) AS GoldBadges,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE 
            WHEN ph.Comment IS NOT NULL THEN ph.Comment
            ELSE 'No reason provided'
        END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.Rank,
        COALESCE(cp.CloseReasons, 'Open') AS CloseReasons,
        rp.GoldBadges,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.Rank,
    CASE 
        WHEN ps.Rank = 1 THEN 'Top Post for Owner'
        ELSE 'Regular Post'
    END AS PostType,
    CASE 
        WHEN ps.CloseReasons = 'Open' THEN 'No closure issues'
        ELSE 'Closed with reasons: ' || ps.CloseReasons
    END AS ClosureStatus,
    ps.GoldBadges,
    ps.UpVotes,
    ps.DownVotes,
    CASE 
        WHEN ps.ViewCount IS NULL THEN 0 
        ELSE ps.ViewCount * (LOG(ps.Score + 1) / NULLIF(ps.CommentCount, 0)) 
    END AS EngagementScore
FROM 
    PostStatistics ps
WHERE 
    ps.GoldBadges > 0 OR ps.UpVotes > ps.DownVotes
ORDER BY 
    EngagementScore DESC, ps.CreationDate DESC
LIMIT 100;

