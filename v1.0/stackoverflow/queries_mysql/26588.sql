
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentsCount,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '<', -1) AS TagName
            FROM 
                (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                 SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                 SELECT 9 UNION ALL SELECT 10) numbers
            WHERE 
                CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) t ON TRUE
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankByScore <= 5 THEN 'Top 5 Posts'
            WHEN rp.ViewCount > 1000 THEN 'Highly Viewed'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    PostCategory,
    COUNT(PostId) AS TotalPosts,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViewCount,
    GROUP_CONCAT(DISTINCT OwnerDisplayName SEPARATOR ', ') AS Contributors,
    GROUP_CONCAT(DISTINCT TagList SEPARATOR '; ') AS TagsSummary
FROM 
    FilteredPosts
GROUP BY 
    PostCategory
ORDER BY 
    TotalPosts DESC;
