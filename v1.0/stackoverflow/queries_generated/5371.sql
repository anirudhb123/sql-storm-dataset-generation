WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)
SELECT 
    up.UserId, 
    up.Reputation, 
    rp.PostId, 
    rp.Title, 
    rp.CreationDate,
    rp.Score, 
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
WHERE 
    up.Reputation > 1000
    AND rp.UserPostRank <= 5
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC;
