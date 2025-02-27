
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
), FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score' 
            ELSE CONCAT('Score: ', rp.Score) 
        END AS ScoreText
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
    OR 
        EXISTS (
            SELECT 
                1 
            FROM 
                Votes v
            WHERE 
                v.PostId = rp.Id 
                AND v.VoteTypeId = 2 
        )
), PostDetails AS (
    SELECT 
        fp.*,
        CASE 
            WHEN fp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus,
        COALESCE(
            (SELECT 
                GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
             FROM 
                Tags t 
             JOIN 
                (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag_name
                 FROM 
                    (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
                 WHERE 
                     CHAR_LENGTH(p.Tags)
                     -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_names 
             ON t.TagName = tag_names.tag_name
             WHERE 
                p.Id = fp.Id), 
            'No Tags') AS Tags
    FROM 
        FilteredPosts fp
    JOIN 
        Posts p ON fp.Id = p.Id
)
SELECT 
    pd.Id,
    pd.Title,
    pd.ScoreText,
    pd.CommentStatus,
    pd.Tags
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 0
ORDER BY 
    pd.Score DESC,
    pd.CreationDate DESC
LIMIT 10;
