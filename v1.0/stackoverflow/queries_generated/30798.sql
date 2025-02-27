WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,  -- Count of Upvotes
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes, -- Count of Downvotes
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosureStatus  -- 1 if closed, else 0
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    tu.DisplayName,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    phs.EditCount,
    phs.LastEdited,
    CASE 
        WHEN phs.ClosureStatus = 1 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    DATEDIFF(day, rp.CreationDate, GETDATE()) AS DaysSinceCreation
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId) -- Join with top users
LEFT JOIN 
    PostHistoryStats phs ON rp.PostId = phs.PostId
WHERE 
    rp.RankScore <= 5  -- Top 5 in each PostType
ORDER BY 
    rp.Score DESC, 
    tu.TotalUpvotes DESC;
