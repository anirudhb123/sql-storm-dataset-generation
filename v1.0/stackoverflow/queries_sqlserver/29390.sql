
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
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_SPLIT(p.Tags, '>') AS t ON 1=1
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0 AND
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    TopPerformers tp ON u.Id = (SELECT TOP 1 p.OwnerUserId FROM Posts p WHERE p.Id = tp.PostId)
ORDER BY 
    u.Reputation DESC;
