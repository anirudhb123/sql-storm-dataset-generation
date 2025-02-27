WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- only Questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(vt.VoteTypeId = 2)::int, 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3)::int, 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes vt ON u.Id = vt.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryWithCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.UpVotes,
        us.DownVotes,
        rp.Title,
        rp.CreationDate,
        phwr.CloseReasons
    FROM 
        UserStats us
    JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    LEFT JOIN 
        PostHistoryWithCloseReasons phwr ON rp.PostId = phwr.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.UpVotes,
    u.DownVotes,
    t.Title,
    t.CreationDate,
    COALESCE(phwr.CloseReasons, 'No Closure') AS CloseReasons,
    CASE 
        WHEN t.TotalPosts > 1 THEN 'Multiple Posts'
        ELSE 'Single Post' END AS PostStatus
FROM 
    TopUsers u
LEFT JOIN 
    RankedPosts t ON u.UserId = t.OwnerUserId
WHERE 
    u.Reputation > 1000 -- Filter for users with reputation greater than 1000
ORDER BY 
    u.Reputation DESC, t.CreationDate DESC;
