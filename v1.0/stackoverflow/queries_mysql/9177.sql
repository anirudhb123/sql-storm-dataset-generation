
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT TagName FROM (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1)) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS t) AS t ON TRUE
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.TagsArray
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.TagsArray,
    (SELECT COUNT(DISTINCT ph.UserId) 
     FROM PostHistory ph 
     WHERE ph.PostId = pp.PostId AND ph.PostHistoryTypeId IN (10, 11, 12, 13)) AS CloseActionCount,
    (SELECT COUNT(DISTINCT v.UserId) 
     FROM Votes v 
     WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2) AS UpvoteCount
FROM 
    TopPosts pp
ORDER BY 
    pp.Score DESC, pp.CreationDate ASC;
