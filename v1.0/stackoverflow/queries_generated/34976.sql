WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS VoteBalance,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostHistoryStats AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosed,
        MAX(CASE WHEN PostHistoryTypeId = 11 THEN CreationDate END) AS LastReopened,
        COUNT(*) AS EditCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
),
FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteBalance,
        pu.DisplayName AS PostOwner,
        w.EditCount,
        w.LastClosed,
        w.LastReopened,
        tu.UserId AS TopUserId,
        tu.DisplayName AS TopUserDisplayName
    FROM 
        RecentPosts rp
    LEFT JOIN 
        PostHistoryStats w ON rp.PostId = w.PostId
    LEFT JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    WHERE 
        rp.CommentCount > 5
    ORDER BY 
        rp.VoteBalance DESC, rp.CreationDate DESC
)
SELECT 
    *,
    CASE 
        WHEN LastClosed IS NOT NULL THEN 'Closed'
        WHEN LastReopened IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FinalResult
WHERE 
    PostRank <= 5
ORDER BY 
    VoteBalance DESC, CreationDate DESC;
