
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.ViewCount,
        p.Score,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS tag
         FROM Posts p 
         INNER JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
                     SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
                     SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
                     SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) as tag ON tag.tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        TagName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        trp.Score,
        trp.TagName,
        GROUP_CONCAT(c.Text SEPARATOR ' | ') AS Comments,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        Comments c ON c.PostId = trp.PostId
    LEFT JOIN 
        Votes v ON v.PostId = trp.PostId
    GROUP BY 
        trp.PostId, trp.Title, trp.CreationDate, trp.ViewCount, trp.Score, trp.TagName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagName,
    pd.Comments,
    pd.Upvotes,
    CASE 
        WHEN pd.Score > 10 THEN 'Popular'
        WHEN pd.Score BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC,
    pd.Score DESC;
