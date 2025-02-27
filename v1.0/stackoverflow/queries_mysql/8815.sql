
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
)
SELECT 
    trp.Title,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.Score,
    trp.ViewCount,
    pt.Tag,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Comments c ON c.PostId = trp.PostId
LEFT JOIN 
    Votes v ON v.PostId = trp.PostId
LEFT JOIN 
    PostTags pt ON pt.PostId = trp.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.CreationDate, trp.OwnerDisplayName, trp.Score, trp.ViewCount, pt.Tag
ORDER BY 
    trp.Score DESC;
