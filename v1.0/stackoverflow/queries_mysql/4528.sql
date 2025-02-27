
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        @row_num := IF(@prev_user = p.OwnerUserId, @row_num + 1, 1) AS UserPostRank,
        @prev_user := p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0, @prev_user := NULL) AS vars
    WHERE 
        p.CreationDate >= TIMESTAMPADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
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
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS CloseCount,
        MAX(ph.CreationDate) AS LastCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    tu.DisplayName,
    rp.Title,
    rp.Score,
    rp.CommentCount,
    tu.TotalScore,
    tu.PostCount,
    cp.CloseCount,
    cp.LastCloseDate
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.UserPostRank <= 3
ORDER BY 
    tu.TotalScore DESC, rp.Score DESC;
