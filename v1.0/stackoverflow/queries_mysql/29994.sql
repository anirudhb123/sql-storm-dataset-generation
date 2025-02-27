
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
),
TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', n.n), ',', -1)) AS TagName,
        COUNT(*) AS PostCount,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= n.n - 1
    WHERE 
        TagRank <= 5 
    GROUP BY 
        TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AverageScore,
    ts.TotalViews,
    ua.DisplayName AS UserName,
    ua.QuestionCount,
    ua.TotalBadges,
    ua.TotalViews AS UserTotalViews,
    ua.AverageBounty
FROM 
    TagStats ts
JOIN 
    UserActivity ua ON ts.PostCount > 5 
ORDER BY 
    ts.TotalViews DESC, 
    ts.AverageScore DESC;
