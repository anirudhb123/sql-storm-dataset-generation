
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMPADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.ScoreRank,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        COALESCE(t.TagName, 'No Tags') AS TagName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            p.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         INNER JOIN 
            Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) t ON rp.PostId = t.Id
    WHERE 
        rp.ScoreRank <= 5
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.Upvotes,
    pd.Downvotes,
    GROUP_CONCAT(DISTINCT pd.TagName ORDER BY pd.TagName ASC SEPARATOR ', ') AS Tags
FROM 
    PostDetails pd
GROUP BY 
    pd.PostId, pd.Title, pd.Score, pd.CreationDate, pd.ViewCount, pd.OwnerDisplayName, pd.CommentCount, pd.Upvotes, pd.Downvotes
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC
LIMIT 50;
