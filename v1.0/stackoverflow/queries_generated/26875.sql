WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COUNT(a.Id) AS AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS LatestActivityRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, u.Reputation, p.CreationDate
),
TagStats AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
    GROUP BY 
        TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.Reputation,
    rp.AnswerCount,
    ts.PostCount AS TagPostCount,
    ts.TotalViews AS TagTotalViews,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.CreationDate,
    rp.LatestActivityRank
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON rp.Tags ILIKE '%' || ts.TagName || '%'  -- Check for tags within the question's tags
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.LatestActivityRank = 1  -- Get only the latest activity
ORDER BY 
    rp.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;  -- Limit results for benchmarking
