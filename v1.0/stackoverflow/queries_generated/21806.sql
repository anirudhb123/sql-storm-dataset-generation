WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN (p.AcceptedAnswerId IS NOT NULL) THEN 1 ELSE 0 END, 0)) AS TotalAcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM 
        PopularTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) >= 5  -- tags used in at least 5 questions
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ua.TotalViews,
    ua.TotalAcceptedAnswers,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score' 
        WHEN rp.Score > 0 THEN 'Positive'
        WHEN rp.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS PostScoreStatus,
    tc.Tag,
    tc.TagUsage
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.rn = 1 -- Most recent post
LEFT JOIN 
    TagCounts tc ON EXISTS (
        SELECT 1
        FROM PopularTags pt
        WHERE pt.Tag = tc.Tag
        AND tc.Tag IN (
            SELECT UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags) - 2), '><')))
        )
    )
WHERE 
    u.Reputation > 1000 -- filter for active users
ORDER BY 
    ua.TotalViews DESC NULLS LAST,  -- placing users with no views at the end
    u.DisplayName ASC, 
    rp.CreationDate DESC
LIMIT 10;
