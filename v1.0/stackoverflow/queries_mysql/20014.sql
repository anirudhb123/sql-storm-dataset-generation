
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.LastActivityDate,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.ViewCount IS NOT NULL AND 
        (p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = p.PostTypeId) OR p.ViewCount > 1000)
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.PostType,
        COALESCE(uc.UserCount, 0) AS UniqueCommenters,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(DISTINCT UserId) AS UserCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) uc ON rp.PostId = uc.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(Id) AS BadgeCount 
        FROM 
            Badges 
        WHERE 
            Class = 1  
        GROUP BY 
            UserId
    ) b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank <= 5
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.PostType,
    pd.UniqueCommenters,
    pd.BadgeCount,
    CASE 
        WHEN pd.Score IS NULL THEN 'No Score'
        WHEN pd.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreStatus,
    GROUP_CONCAT(DISTINCT SUBSTRING(t.TagName, 2, LENGTH(t.TagName) - 2) ORDER BY t.TagName SEPARATOR ',') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    (SELECT 
         PostId, 
         SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
     FROM 
         Posts 
     JOIN 
         (SELECT a.N + b.N * 10 AS n
          FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
              SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
              SELECT 8 UNION ALL SELECT 9) a 
           , 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
              SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
              SELECT 8 UNION ALL SELECT 9) b) n
     ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
     WHERE Tags IS NOT NULL) t ON pd.PostId = t.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.ViewCount, pd.Score, pd.PostType, pd.UniqueCommenters, pd.BadgeCount
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC;
