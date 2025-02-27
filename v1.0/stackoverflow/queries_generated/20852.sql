WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(rp.ViewCount) AS TotalViewCount,
        AVG(rp.CommentCount) AS AverageComments,
        AVG(rp.UpVotes) AS AverageUpVotes,
        AVG(rp.DownVotes) AS AverageDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation >= 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::integer = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    COALESCE(cr.CloseReasonNames, 'None') AS CloseReasons,
    us.TotalViewCount,
    us.AverageComments,
    us.AverageUpVotes,
    us.AverageDownVotes
FROM 
    UserStats us
LEFT JOIN 
    CloseReasons cr ON us.UserId = (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM CloseReasons))
WHERE 
    us.AverageComments > 0
ORDER BY 
    us.Reputation DESC, us.TotalViewCount DESC
LIMIT 10;

-- Include cases where there are NULLs in BadgeCount, use COALESCE
-- Also utilize bizarre string functions for CloseReasons (STRING_AGG) 
-- and represent results that might involve hidden semantic connectivity (via sub-query)
