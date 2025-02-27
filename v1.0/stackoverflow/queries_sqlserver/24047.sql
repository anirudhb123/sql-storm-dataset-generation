
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
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate
), FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score' 
            ELSE 'Score: ' + CAST(rp.Score AS NVARCHAR(50)) 
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
                STRING_AGG(DISTINCT t.TagName, ', ') 
             FROM 
                Tags t 
             JOIN 
                STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag_name ON t.TagName = tag_name.value
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
