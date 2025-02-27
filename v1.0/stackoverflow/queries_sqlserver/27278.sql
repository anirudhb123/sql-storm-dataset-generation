
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
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),
FrequentTags AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
        FrequentTags ft ON rp.Title LIKE '%' + ft.Tag + '%'
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.DisplayName,
    pd.PostType,
    pd.CommentCount,
    STRING_AGG(DISTINCT pd.Tag, ',') AS Tags,
    SUM(pd.TagCount) AS TotalTagCount
FROM 
    PostDetails pd
GROUP BY 
    pd.PostId, pd.Title, pd.DisplayName, pd.PostType, pd.CommentCount
ORDER BY 
    TotalTagCount DESC, pd.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
