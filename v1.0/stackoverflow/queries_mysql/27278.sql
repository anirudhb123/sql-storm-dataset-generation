
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),
FrequentTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 
            UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 
            UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
            UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 3
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.DisplayName,
        rp.PostType,
        rp.CommentCount,
        ft.Tag,
        ft.TagCount
    FROM 
        RankedPosts rp
    JOIN 
        FrequentTags ft ON rp.Title LIKE CONCAT('%', ft.Tag, '%')
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.DisplayName,
    pd.PostType,
    pd.CommentCount,
    GROUP_CONCAT(DISTINCT pd.Tag) AS Tags,
    SUM(pd.TagCount) AS TotalTagCount
FROM 
    PostDetails pd
GROUP BY 
    pd.PostId, pd.Title, pd.DisplayName, pd.PostType, pd.CommentCount
ORDER BY 
    TotalTagCount DESC, pd.CommentCount DESC
LIMIT 10;
