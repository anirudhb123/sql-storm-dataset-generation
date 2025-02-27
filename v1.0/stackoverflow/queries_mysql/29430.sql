
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        p.LastActivityDate,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TagPostCounts AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '> <', n.n), '> <', -1)) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    WHERE 
        Tags IS NOT NULL 
    GROUP BY 
        TagName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS RankByCount
    FROM 
        TagPostCounts
    WHERE 
        PostCount > 10
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.OwnerDisplayName,
        rp.PostTypeName,
        pt.Name AS CloseReason,
        CASE 
            WHEN rp.LastActivityDate < NOW() - INTERVAL 6 MONTH THEN 'Inactivity Detected'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment = CAST(pt.Id AS CHAR)
    WHERE 
        rp.RankByViews <= 5
)
SELECT 
    pp.Title,
    pp.ViewCount,
    pp.AnswerCount,
    pp.CommentCount,
    pp.CreationDate,
    pp.LastActivityDate,
    pp.OwnerDisplayName,
    pp.PostTypeName,
    pt.TagName,
    pt.PostCount,
    pp.CloseReason,
    pp.ActivityStatus
FROM 
    PopularPosts pp
JOIN 
    PopularTags pt ON pp.Title LIKE CONCAT('%', pt.TagName, '%')
ORDER BY 
    pp.ViewCount DESC, 
    pp.CreationDate DESC;
