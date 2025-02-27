WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPerType
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
        AND p.PostTypeId IN (1, 2) -- Questions and Answers
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, ',')) AS TagName
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only questions
),
TagDensity AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5 -- Only consider tags used more than 5 times
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100 -- Consider users with reputation greater than 100
    GROUP BY 
        u.Id
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVoteCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    d.TagName AS MostPopularTag,
    ua.DisplayName AS ActiveUser,
    ua.TotalViews,
    ph.LastClosedDate,
    ph.CloseVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserActivity ua ON ua.PostCount > 10 -- Join with active users having more than 10 posts
LEFT JOIN 
    TagDensity d ON d.TagCount = (SELECT MAX(TagCount) FROM TagDensity) -- Most popular tag
LEFT JOIN 
    PostHistoryAggregated ph ON ph.PostId = rp.PostId
WHERE 
    rp.RN <= 5 -- Top 5 posts by score per type
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
