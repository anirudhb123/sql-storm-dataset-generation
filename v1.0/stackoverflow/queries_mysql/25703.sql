
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUserActivity
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(*) AS TotalPosts,
        SUM(p.AnswerCount) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    u.DisplayName AS UserDisplayName,
    ue.TotalPosts,
    ue.TotalAnswers,
    ue.TotalViews,
    tt.TagName,
    rp.RankByViewCount,
    rp.RankByUserActivity
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
JOIN 
    TopTags tt ON FIND_IN_SET(tt.TagName, rp.Tags) > 0
WHERE 
    rp.RankByViewCount <= 5 
    AND rp.RankByUserActivity <= 3
ORDER BY 
    rp.RankByViewCount, ue.TotalViews DESC;
