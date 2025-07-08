
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
        LATERAL SELECT 
            TRIM(value) AS TagName
        FROM 
            TABLE(FLATTEN(input => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))) 
    ) tags ON TRUE
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, tags.TagName
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
        DATEDIFF('hour', LAG(fp.CreationDate) OVER (ORDER BY fp.CreationDate), fp.CreationDate) AS HoursBetweenPosts
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
