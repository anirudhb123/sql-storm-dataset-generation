
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01')
),
TopTags AS (
    SELECT 
        TRIM(value) AS TagName
    FROM 
        RecentPosts
    CROSS APPLY STRING_SPLIT(Tags, ',')
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagFrequency
    FROM 
        TopTags
    GROUP BY 
        TagName
    ORDER BY 
        TagFrequency DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(COALESCE(b.Class, 0)) > 0
    ORDER BY 
        BadgeScore DESC
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RecentPosts rp
    JOIN 
        UserReputations ur ON rp.OwnerDisplayName = ur.DisplayName
    WHERE 
        ur.BadgeScore > 1
    ORDER BY 
        rp.Score DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.OwnerDisplayName,
    tc.TagName
FROM 
    PopularPosts pp
JOIN 
    TagCounts tc ON pp.PostId IN (
        SELECT 
            PostId 
        FROM 
            Posts 
        WHERE 
            Tags LIKE '%' + tc.TagName + '%'
    )
ORDER BY 
    pp.Score DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
