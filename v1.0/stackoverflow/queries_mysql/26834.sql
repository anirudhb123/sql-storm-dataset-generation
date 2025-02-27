
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        tags.TagName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '>', -1) AS TagName
            FROM 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
                 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
            WHERE 
                CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) tags ON TRUE
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        p.Id, u.DisplayName, tags.TagName
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.Author, 
        rp.TagName, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 
        AND rp.CommentCount > 5
), BenchmarkedPosts AS (
    SELECT 
        fp.*, 
        LAG(fp.CreationDate) OVER (ORDER BY fp.CreationDate) AS PreviousPostDate,
        TIMESTAMPDIFF(SECOND, LAG(fp.CreationDate) OVER (ORDER BY fp.CreationDate), fp.CreationDate) / 3600 AS HoursBetweenPosts
    FROM 
        FilteredPosts fp
)
SELECT 
    bp.PostId,
    bp.Title,
    bp.Body,
    bp.Author,
    bp.CreationDate,
    bp.TagName,
    bp.CommentCount,
    COALESCE(bp.HoursBetweenPosts, 0) AS HoursSinceLastPost
FROM 
    BenchmarkedPosts bp
ORDER BY 
    bp.CommentCount DESC,
    bp.CreationDate DESC
LIMIT 100;
