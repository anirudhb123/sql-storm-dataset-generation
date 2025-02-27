
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        U.Reputation AS UserReputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    JOIN 
        (SELECT 
            p.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM 
            Posts p
        INNER JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, U.Reputation, p.PostTypeId
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        pa.CommentCount,
        pa.EditCount,
        rp.Tags
    FROM 
        RankedPosts rp
    JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
    WHERE 
        rp.RankScore <= 3 
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    COALESCE(tp.CommentCount, 0) AS TotalComments,
    COALESCE(tp.EditCount, 0) AS TotalEdits,
    CASE 
        WHEN tp.Score IS NULL THEN 'No Score'
        WHEN tp.Score > 100 THEN 'Hot Post'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Needs Attention'
    END AS EngagementLevel,
    CASE 
        WHEN tp.Tags IS NOT NULL THEN LENGTH(tp.Tags) - LENGTH(REPLACE(tp.Tags, ', ', '')) + 1 
        ELSE 0 
    END AS TagCount
FROM 
    TopPosts tp
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 2 
WHERE 
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.Id = tp.PostId AND p.AcceptedAnswerId IS NOT NULL
    )
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
