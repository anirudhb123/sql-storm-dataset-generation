
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerDisplayName,
        r.Score,
        r.CreationDate
    FROM 
        RankedPosts r
    WHERE 
        r.PostRank <= 5 
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.Score,
        tp.CreationDate,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        (
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, ', ', n.n), ', ', -1) AS TagName,
                Posts.Id AS PostId
            FROM 
                Posts
            INNER JOIN 
                (SELECT a.N + b.N * 10 + 1 n FROM 
                    (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
                    (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
                ) n ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, ', ', '')) >= n.n - 1
        ) t ON t.PostId = tp.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.OwnerDisplayName, tp.Score, tp.CreationDate
),
VotesSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.Score,
    pd.CreationDate,
    pd.Tags,
    COALESCE(vs.Upvotes, 0) AS Upvotes,
    COALESCE(vs.Downvotes, 0) AS Downvotes
FROM 
    PostDetails pd
LEFT JOIN 
    VotesSummary vs ON pd.PostId = vs.PostId
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
