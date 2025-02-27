
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
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') AS value
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        LTRIM(RTRIM(value))
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    TopTags tt ON tt.TagName IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(rp.Tags, '>'))
WHERE 
    rp.RankByViewCount <= 5 
    AND rp.RankByUserActivity <= 3
ORDER BY 
    rp.RankByViewCount, ue.TotalViews DESC;
