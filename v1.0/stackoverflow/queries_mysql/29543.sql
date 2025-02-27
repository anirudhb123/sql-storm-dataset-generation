
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        GROUP_CONCAT(t.TagName) AS TagsList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.PostType,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        rp.TagsList
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerName,
    fp.PostType,
    fp.Score,
    fp.ViewCount,
    fp.TagsList,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    FilteredPosts fp
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerName, fp.PostType, fp.Score, fp.ViewCount, fp.TagsList
ORDER BY 
    fp.Score DESC, CommentCount DESC;
