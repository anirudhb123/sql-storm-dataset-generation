WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Only considering Questions and Answers
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::integer = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    cr.CloseReasons,
    cr.FirstCloseDate,
    us.DisplayName AS UserDisplayName,
    us.UpVotesCount,
    us.DownVotesCount,
    us.TotalBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPostReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    Posts p ON p.AcceptedAnswerId = rp.PostId
LEFT JOIN 
    Users us ON p.OwnerUserId = us.Id
WHERE 
    rp.Rank <= 5 -- Top 5 posts by score
    AND (cr.CloseReasons IS NOT NULL OR us.Reputation > 1000) -- Show either closed posts or users with high reputation
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC;

