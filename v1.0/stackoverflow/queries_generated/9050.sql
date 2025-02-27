WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        PostCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    tu.PostCount,
    tu.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.Id IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId LIMIT 1)
WHERE 
    rp.Score > 10
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC
LIMIT 10;
