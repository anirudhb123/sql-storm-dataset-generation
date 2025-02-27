WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'Experienced'
            WHEN u.Reputation >= 100 THEN 'Novice'
            ELSE 'Beginner' 
        END AS UserLevel
    FROM 
        Users u
)
SELECT 
    up.DisplayName AS UserName,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    up.Reputation,
    up.UserLevel,
    rp.ScoreRank
FROM 
    RankedPosts rp
INNER JOIN 
    UserReputation up ON rp.OwnerUserId = up.UserId
WHERE 
    rp.rn = 1 
    AND rp.CommentCount > 5 
    AND (rp.UpVotes - rp.DownVotes) > 10
ORDER BY 
    up.Reputation DESC, 
    rp.ScoreRank ASC
LIMIT 50;

SELECT 
    p.Id,
    p.Title,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= (NOW() - INTERVAL '1 month') 
GROUP BY 
    p.Id, p.Title
HAVING 
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) >= 3;

SELECT 
    pt.Name AS PostTypeName, 
    COUNT(p.Id) AS NumberOfPosts 
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name;
