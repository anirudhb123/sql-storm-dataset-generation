WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserScoreRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        u.Id
    HAVING 
        SUM(p.Score) > 10
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    tu.DisplayName AS TopUser,
    tu.TotalScore,
    vs.UpVotes,
    vs.DownVotes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.UserRank = 1 AND rp.PostId IN (SELECT PostId FROM Votes GROUP BY PostId HAVING COUNT(v.Id) > 5)
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
WHERE 
    rp.CommentCount > 0
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
