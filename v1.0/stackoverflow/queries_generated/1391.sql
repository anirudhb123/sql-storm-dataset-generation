WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    rp.Id AS PostId,
    rp.Title,
    rp.Score,
    COALESCE(rv.UpVotes, 0) AS UpVotes,
    COALESCE(rv.DownVotes, 0) AS DownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    CASE 
        WHEN rp.Score > 10 THEN 'High Score'
        WHEN rp.Score BETWEEN 1 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
