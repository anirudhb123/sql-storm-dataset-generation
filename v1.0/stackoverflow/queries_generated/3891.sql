WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '5 years'
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.Score) > 1000
),
RecentPostHistory AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate, 
        ph.Comment, 
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
        AND ph.CreationDate >= NOW() - INTERVAL '3 months'
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate AS PostCreationDate, 
    rp.Score, 
    rp.ViewCount, 
    rp.CommentCount, 
    tu.DisplayName AS TopUserDisplayName, 
    tu.TotalScore,
    rph.HistoryDate, 
    rph.Comment AS HistoryComment, 
    rph.UserDisplayName AS EditorName
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    rp.RankByScore <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
