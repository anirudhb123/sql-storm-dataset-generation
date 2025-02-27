
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
),

TopPosts AS (
    SELECT 
        r.*, 
        u.DisplayName AS OwnerDisplayName
    FROM 
        RankedPosts r
    JOIN 
        Users u ON r.OwnerUserId = u.Id
    WHERE 
        r.Rank <= 5 
),

PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVoteCount,
        tp.DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList
    FROM 
        TopPosts tp
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', numbers.n), '><', -1) tag
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
          SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
          SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
          SELECT 10) numbers
         WHERE CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, '><', '')) >= numbers.n - 1) AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_array.tag
    GROUP BY 
        tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.OwnerDisplayName, tp.CommentCount, tp.UpVoteCount, tp.DownVoteCount
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.TagsList
FROM 
    PostDetails pd
ORDER BY 
    pd.UpVoteCount DESC, pd.CommentCount DESC;
