WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 50
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
PostAnalytics AS (
    SELECT 
        tp.UserId,
        tu.DisplayName,
        COUNT(DISTINCT tp.PostId) AS TotalPosts,
        SUM(tp.Score) AS SumScores,
        SUM(tp.CommentCount) AS TotalComments,
        COUNT(DISTINCT cp.ClosedDate) AS ClosedPostCount
    FROM 
        TopUsers tu
    LEFT JOIN 
        RankedPosts tp ON tu.UserId = tp.OwnerUserId
    LEFT JOIN 
        ClosedPosts cp ON tp.PostId = cp.Id
    GROUP BY 
        tp.UserId, tu.DisplayName
)
SELECT 
    pa.DisplayName,
    pa.TotalPosts,
    pa.SumScores,
    pa.TotalComments,
    COALESCE(pa.ClosedPostCount, 0) AS ClosedPostCount
FROM 
    PostAnalytics pa
WHERE 
    pa.SumScores > 100
ORDER BY 
    pa.SumScores DESC
LIMIT 10
OFFSET 0;
