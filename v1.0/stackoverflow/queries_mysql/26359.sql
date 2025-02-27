
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 30 DAY) 
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, a.AnswerCount
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RecentPosts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
AggStats AS (
    SELECT 
        rp.OwnerDisplayName,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.VoteCount) AS TotalVotes,
        SUM(rp.AnswerCount) AS TotalAnswers,
        GROUP_CONCAT(DISTINCT tt.Tag) AS TopTags
    FROM 
        RecentPosts rp
    LEFT JOIN 
        TopTags tt ON FIND_IN_SET(tt.Tag, rp.Tags)
    GROUP BY 
        rp.OwnerDisplayName
)
SELECT 
    OwnerDisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalAnswers,
    TopTags
FROM 
    AggStats
ORDER BY 
    TotalPosts DESC;
