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
        p.PostTypeId = 1 -- Only considering questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        AVG(Score) AS AverageScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5 -- Top 5 posts ranked by score per tag
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
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Only questions
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart votes
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
    UserActivity ua ON ts.PostCount > 5 -- Join on tags with more than 5 posts
ORDER BY 
    ts.TotalViews DESC, 
    ts.AverageScore DESC;
