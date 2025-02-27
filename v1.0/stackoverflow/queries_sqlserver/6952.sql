
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.Score,
    rp.OwnerName,
    rp.CommentCount,
    rp.UpVoteCount,
    tu.DisplayName AS TopUserName,
    tu.TotalScore,
    tu.TotalViews
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.OwnerName = tu.DisplayName
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
