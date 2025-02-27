
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR AND 
        p.Score > 0
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName SEPARATOR ',') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT PostId, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS tag ON true
    JOIN 
        Tags t ON t.TagName = tag.TagName
    GROUP BY 
        p.Id
),
PostStats AS (
    SELECT 
        pt.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        PostTags pt
    LEFT JOIN 
        Comments c ON pt.PostId = c.PostId
    LEFT JOIN 
        Votes v ON pt.PostId = v.PostId
    GROUP BY 
        pt.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.CreationDate,
    trp.OwnerDisplayName,
    pt.Tags,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTags pt ON trp.PostId = pt.PostId
LEFT JOIN 
    PostStats ps ON trp.PostId = ps.PostId
ORDER BY 
    trp.Score DESC;
