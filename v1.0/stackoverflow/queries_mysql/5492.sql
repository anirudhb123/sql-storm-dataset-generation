
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        @row_number := IF(@current_post_type = pt.Name, @row_number + 1, 1) AS Rank,
        @current_post_type := pt.Name,
        pt.Name AS PostTypeName,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0, @current_post_type := '') AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.CommentCount, u.DisplayName, pt.Name
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    rp.PostTypeName,
    rp.Rank,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRankClassification
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.PostTypeName, rp.Rank;
