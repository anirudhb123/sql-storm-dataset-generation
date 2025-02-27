
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
), 
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.Tags IS NOT NULL
),
TagUsage AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM 
        PostTagCounts
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10 
),
TopPosts AS (
    SELECT 
        rp.*,
        GROUP_CONCAT(t.Tag ORDER BY t.Tag SEPARATOR ', ') AS UsedTags
    FROM 
        RankedPosts rp
    JOIN 
        PostTagCounts pt ON rp.PostId = pt.PostId
    JOIN 
        TagUsage t ON pt.Tag = t.Tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.CreationDate, rp.OwnerDisplayName, rp.OwnerReputation, rp.VoteCount, rp.VoteRank
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    tp.VoteCount,
    tp.VoteRank,
    tp.UsedTags
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 5 
ORDER BY 
    tp.VoteCount DESC;
