WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
),
TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.CreationDate,
    rp.LastActivityDate,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AverageViews,
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE CONCAT('%<', ts.TagName, '>%')
JOIN 
    Users u ON u.Id = rp.OwnerUserId
JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    rp.Rank <= 5 -- Return top 5 questions per user
ORDER BY 
    rp.LastActivityDate DESC, 
    ts.TotalViews DESC;
