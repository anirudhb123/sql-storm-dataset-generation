
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpvoteCount - rp.DownvoteCount > 10 THEN 'Highly Voted'
            WHEN rp.UpvoteCount - rp.DownvoteCount BETWEEN 1 AND 10 THEN 'Moderately Voted'
            ELSE 'Low Interaction' 
        END AS VoteCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 
),
TagsStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TopPosts,
        (SELECT a.N + b.N * 10 AS n
         FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    WHERE 
        n.n < 1 + LENGTH(Tags) - LENGTH(REPLACE(Tags, '>', ''))
    GROUP BY 
        TagName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.VoteCategory,
    ts.TagName,
    ts.TagCount
FROM 
    TopPosts tp
LEFT JOIN 
    TagsStats ts ON tp.Tags LIKE CONCAT('%', ts.TagName, '%')
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
