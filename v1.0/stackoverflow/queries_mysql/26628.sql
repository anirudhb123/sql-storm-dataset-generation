
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId 
            AND a.PostTypeId = 2 
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, p.Tags
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
        AND rp.Score > 5 
        AND rp.ViewCount > 100 
        AND rp.AnswerCount > 0
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Tags,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS TagsList,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = fp.PostId 
       AND v.VoteTypeId = 2) AS TotalUpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = fp.PostId 
       AND v.VoteTypeId = 3) AS TotalDownVotes
FROM 
    FilteredPosts fp
    LEFT JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, ',', numbers.n), ',', -1)) as tag_name
                FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                      SELECT 9 UNION ALL SELECT 10) numbers
                WHERE CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, ',', '')) >= numbers.n - 1) AS tag_name 
    LEFT JOIN Tags t ON t.TagName = tag_name
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, fp.Score, fp.ViewCount, fp.Tags
ORDER BY 
    fp.Score DESC,
    fp.ViewCount DESC;
