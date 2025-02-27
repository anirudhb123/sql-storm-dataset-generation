WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) AND -- Only Questions and Answers
        p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        ua.UserId,
        ua.PostCount,
        ua.TotalBounty,
        ua.AvgViewCount,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
        COALESCE(pt.TagCount, 0) AS PopularTagCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        UserBadges ub ON ua.UserId = ub.UserId
    LEFT JOIN 
        (SELECT 
            p.OwnerUserId,
            SUM(pt.TagCount) AS TagCount
        FROM 
            Posts p
        JOIN 
            PopularTags pt ON pt.TagName = ANY (string_to_array(p.Tags, '><'))
        GROUP BY 
            p.OwnerUserId) pt ON ua.UserId = pt.OwnerUserId
)
SELECT 
    fr.UserId,
    fr.PostCount,
    fr.TotalBounty,
    fr.AvgViewCount,
    fr.BadgeCount,
    fr.BadgeNames,
    CASE 
        WHEN fr.PostCount >= 10 THEN 'Active'
        WHEN fr.PostCount BETWEEN 5 AND 9 THEN 'Moderate'
        ELSE 'Inactive'
    END AS UserActivityLevel,
    CASE 
        WHEN fr.PopularTagCount > 0 THEN 'Has Popular Tags'
        ELSE 'No Popular Tags'
    END AS TagStatus,
    COUNT(*) FILTER (WHERE np.PostId IS NOT NULL) AS NotableQuestionsCount
FROM 
    FinalResults fr
LEFT JOIN 
    RankedPosts np ON fr.UserId = np.OwnerUserId AND np.rn <= 5
GROUP BY 
    fr.UserId, fr.PostCount, fr.TotalBounty, fr.AvgViewCount, fr.BadgeCount, 
    fr.BadgeNames, fr.PopularTagCount
ORDER BY 
    fr.TotalBounty DESC, fr.PostCount DESC;
