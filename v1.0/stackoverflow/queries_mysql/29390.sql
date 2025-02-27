
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
         FROM Posts p 
         INNER JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0 AND
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPerformers AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.UniqueVoterCount,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UniqueVoterCount,
    tp.ViewCount,
    tp.Tags
FROM 
    Users u
JOIN 
    TopPerformers tp ON u.Id = (SELECT DISTINCT p.OwnerUserId FROM Posts p WHERE p.Id = tp.PostId)
ORDER BY 
    u.Reputation DESC;
