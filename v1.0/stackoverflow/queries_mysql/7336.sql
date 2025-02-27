
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @rank:= @rank + 1 AS Rank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId,
        (SELECT @rank := 0) r
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tu.DisplayName AS TopUser,
    tu.TotalBadges,
    tu.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.Rank <= 10
ORDER BY 
    rp.Rank;
