
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COALESCE(REPLACE(SUBSTRING(p.Body, CHARINDEX('<p>', p.Body) + 3, CHARINDEX('</p>', p.Body) - CHARINDEX('<p>', p.Body) - 3), '<p>', ''), '') AS CleanBody,
        (LEN(p.Tags) - LEN(REPLACE(p.Tags, '><', ''))) + 1 AS TagCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
        AND p.ViewCount > 100
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
),
RankedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Body,
        fp.TagCount,
        fp.CommentCount,
        RANK() OVER (ORDER BY fp.CommentCount DESC) AS CommentRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.TagCount,
    CASE 
        WHEN rp.CommentRank <= 10 THEN 'Top Discussion'
        WHEN rp.CommentRank <= 30 THEN 'Moderate Interest'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    LEFT(rp.Body, 200) AS Preview
FROM 
    RankedPosts rp
WHERE 
    rp.TagCount >= 3
ORDER BY 
    rp.CommentRank;
