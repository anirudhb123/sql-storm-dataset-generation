WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
        JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        ph.CreationDate AS ClosedDate,
        COUNT(v.Id) AS CloseVoteCount
    FROM 
        Posts p
        JOIN PostHistory ph ON p.Id = ph.PostId 
        WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        p.Title, p.CreationDate, ph.CreationDate
)
SELECT 
    rp.Title AS PostTitle,
    rp.CreationDate AS PostDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalScore,
    cp.ClosedDate,
    cp.CloseVoteCount
FROM 
    RankedPosts rp
    LEFT JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
    LEFT JOIN ClosedPosts cp ON rp.Title = cp.Title
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
