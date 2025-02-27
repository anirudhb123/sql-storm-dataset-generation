
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT rp.PostId) AS PostCount,
        SUM(rp.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.UserRank
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    GROUP BY 
        v.PostId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes
FROM 
    TopUsers tu
JOIN 
    RankedPosts tp ON tu.PostCount > 5 AND tp.UserRank = 1
LEFT JOIN 
    RecentVotes rv ON tp.PostId = rv.PostId
ORDER BY 
    tu.Reputation DESC, tp.ViewCount DESC;
