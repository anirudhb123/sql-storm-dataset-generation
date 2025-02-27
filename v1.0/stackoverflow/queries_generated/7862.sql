WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        COUNT(DISTINCT rp.PostId) AS PostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT rp.PostId) > 5
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -1, GETDATE())
    GROUP BY 
        ph.UserId, ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    phs.PostId,
    phs.PostHistoryTypeId,
    phs.HistoryCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    TopUsers tu
JOIN 
    PostHistoryStats phs ON tu.UserId = phs.UserId
JOIN 
    RankedPosts rp ON phs.PostId = rp.PostId
ORDER BY 
    tu.TotalScore DESC, tu.DisplayName;
