
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.PostTypeId, p.Score
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    ROUND((tp.UpVoteCount / NULLIF(tp.UpVoteCount + tp.DownVoteCount, 0)) * 100, 2) AS UpVotePercentage,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            Posts p
        INNER JOIN 
            (
                SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
                -- Add more if needed for max tags
            ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS t ON TRUE
WHERE 
    t.TagName IS NOT NULL
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.CommentCount, tp.UpVoteCount, tp.DownVoteCount
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
