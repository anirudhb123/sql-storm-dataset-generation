WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 1000
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(vote.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes vote ON p.Id = vote.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBounty,
        PostCount,
        AvgPostScore,
        RANK() OVER (ORDER BY TotalBounty DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        PostCount > 5
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.TotalBounty,
    u.AvgPostScore,
    CASE 
        WHEN u.UserRank IS NOT NULL THEN u.UserRank
        ELSE 'N/A'
    END AS UserRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers u ON rp.OwnerUserId = u.UserId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    u.TotalBounty DESC;
