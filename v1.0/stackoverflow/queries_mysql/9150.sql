
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT TRIM(TRAILING '>' FROM TRIM(LEADING '<' FROM value)) AS TagName 
         FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS value 
               FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                     UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
               WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.Tags,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS UpVotes
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        rp.RankScore <= 10  
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.Tags, u.DisplayName, u.Reputation
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    tp.OwnerName,
    tp.OwnerReputation,
    tp.UpVotes,
    COALESCE(ph.Comment, 'No changes') AS MostRecentChange
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
WHERE 
    ph.CreationDate = (
        SELECT 
            MAX(p2.CreationDate) 
        FROM 
            PostHistory p2 
        WHERE 
            p2.PostId = tp.PostId
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
