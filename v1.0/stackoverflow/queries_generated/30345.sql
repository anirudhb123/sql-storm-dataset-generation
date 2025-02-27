WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        1 AS Level
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Closed or Reopened posts
    UNION ALL
    SELECT 
        p.Id,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON rph.PostId = ph.PostId
    WHERE 
        ph.CreationDate < rph.HistoryDate  -- Get history prior to the previous entry
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'  
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        DENSE_RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        MAX(rph.HistoryDate) AS LastClosed
    FROM 
        Posts p
    JOIN 
        RecursivePostHistory rph ON p.Id = rph.PostId
    WHERE 
        rph.PostHistoryTypeId = 10  -- Closed posts
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.CommentCount,
    rp.VoteCount,
    rp.AverageBounty,
    cu.DisplayName AS TopUser,
    cu.TotalReputation,
    cp.LastClosed AS LastClosedDate,
    CASE 
        WHEN rp.CommentCount > 10 THEN 'Highly Commented'
        ELSE 'Normal Activity'
    END AS ActivityLevel
FROM 
    RecentPosts rp
LEFT JOIN 
    TopUsers cu ON cu.UserRank = 1  -- Get top user
LEFT JOIN 
    ClosedPosts cp ON cp.Id = rp.PostId
WHERE 
    rp.AverageBounty IS NOT NULL 
    AND rp.CreationDate < NOW() - INTERVAL '1 day'  -- Exclude recent posts
ORDER BY 
    rp.VoteCount DESC, rp.CommentCount DESC;
