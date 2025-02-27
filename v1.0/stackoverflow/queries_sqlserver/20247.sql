
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id),
            0
        ) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
        AND p.Score IS NOT NULL
        AND p.ViewCount > 0
),

UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        AVG(p.Score) AS AveragePostScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    ups.DisplayName AS TopUser,
    ups.PostCount,
    ups.TotalUpVotes,
    ups.AveragePostScore,
    ups.AcceptedAnswers,
    phs.ChangeCount,
    phs.Comments
FROM 
    RankedPosts rp
LEFT JOIN 
    UserPostStatistics ups ON ups.UserId = (
        SELECT TOP 1 u.Id
        FROM Users u
        JOIN Posts pp ON pp.OwnerUserId = u.Id
        WHERE pp.Id = rp.PostId
        ORDER BY u.Reputation DESC
    )
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId = rp.PostId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC,
    ups.TotalUpVotes DESC;
