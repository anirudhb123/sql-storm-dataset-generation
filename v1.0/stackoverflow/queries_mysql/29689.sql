
WITH RankedPosts AS (
    SELECT 
        p.Id AS post_id,
        p.Title AS post_title,
        p.Tags AS post_tags,
        u.DisplayName AS author_name,
        COUNT(c.Id) AS comment_count,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS downvote_count,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName
),
ExpandedTags AS (
    SELECT 
        post_id,
        post_title,
        author_name,
        comment_count,
        upvote_count,
        downvote_count,
        TRIM(tag) AS tag
    FROM 
        RankedPosts
    CROSS JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(post_tags, ',', numbers.n), ',', -1)) AS tag
        FROM 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        WHERE 
        CHAR_LENGTH(post_tags) - CHAR_LENGTH(REPLACE(post_tags, ',', '')) >= numbers.n - 1) AS tags
),
AggregatedData AS (
    SELECT 
        post_title,
        author_name,
        COUNT(DISTINCT post_id) AS total_posts,
        SUM(comment_count) AS total_comments,
        SUM(upvote_count) AS total_upvotes,
        SUM(downvote_count) AS total_downvotes,
        GROUP_CONCAT(DISTINCT tag ORDER BY tag SEPARATOR ', ') AS unique_tags
    FROM 
        ExpandedTags
    GROUP BY 
        post_title, author_name
)
SELECT 
    author_name,
    COUNT(total_posts) AS post_count,
    SUM(total_comments) AS comment_count,
    SUM(total_upvotes) AS upvote_count,
    SUM(total_downvotes) AS downvote_count,
    GROUP_CONCAT(DISTINCT unique_tags SEPARATOR '; ') AS tag_summary
FROM 
    AggregatedData
GROUP BY 
    author_name
ORDER BY 
    post_count DESC;
