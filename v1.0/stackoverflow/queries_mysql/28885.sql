
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AverageUpvotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AverageDownvotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
               SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON true
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, U.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND
        rp.AverageUpvotes > rp.AverageDownvotes
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.CreationDate,
    fp.CommentCount,
    fp.AverageUpvotes,
    fp.AverageDownvotes,
    fp.Tags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC
LIMIT 10;
