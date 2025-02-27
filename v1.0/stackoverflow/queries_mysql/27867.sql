
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
             UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag 
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.CreationDate,
    trp.Score,
    trp.OwnerDisplayName,
    trp.CommentCount,
    pt.Tags,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = trp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = trp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTags pt ON trp.PostId = pt.PostId
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC
LIMIT 10;
