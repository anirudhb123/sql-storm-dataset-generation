
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        @rank := IF(@prev = pt.Name, @rank + 1, 1) AS Rank,
        @prev := pt.Name,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        (SELECT @rank := 0, @prev := '') AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        pt.Name, p.Score DESC, p.ViewCount DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserID,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        ur.UserID,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.TotalScore,
        @userRank := @userRank + 1 AS UserRank
    FROM 
        UserReputation ur
    JOIN 
        (SELECT @userRank := 0) AS vars
    WHERE 
        ur.PostCount > 10
    ORDER BY 
        ur.Reputation DESC
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    top.DisplayName AS OwnerName,
    top.Reputation AS OwnerReputation,
    rp.PostType
FROM 
    RankedPosts rp
JOIN 
    TopUsers top ON rp.OwnerUserId = top.UserID
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.PostType, rp.Score DESC;
