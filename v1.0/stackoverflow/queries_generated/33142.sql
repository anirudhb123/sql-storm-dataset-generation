WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBountyGiven,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        u.Id
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10 -- More than 10 posts using this tag
),
CombinedActivity AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalBountyGiven,
        ua.TotalQuestions,
        ua.TotalComments,
        COALESCE(phc.EditCount, 0) AS EditCount,
        COALESCE(phc.CloseCount, 0) AS CloseCount,
        COUNT(pt.TagName) AS PopularTagCount
    FROM 
        UserActivity ua
    LEFT JOIN 
        PostHistoryCounts phc ON ua.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = phc.PostId)
    LEFT JOIN 
        PopularTags pt ON pt.TagName IN (SELECT unnest(string_to_array(p.Tags, '><')) FROM Posts p WHERE p.OwnerUserId = ua.UserId)
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.TotalBountyGiven, ua.TotalQuestions, ua.TotalComments, phc.EditCount, phc.CloseCount
)
SELECT 
    c.UserId,
    c.DisplayName,
    c.TotalBountyGiven,
    c.TotalQuestions,
    c.TotalComments,
    c.EditCount,
    c.CloseCount,
    c.PopularTagCount,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'PostId', rp.PostId,
            'Title', rp.Title,
            'CreationDate', rp.CreationDate,
            'Score', rp.Score,
            'ViewCount', rp.ViewCount
        )
    ) AS RecentPosts
FROM 
    CombinedActivity c
LEFT JOIN 
    RankedPosts rp ON rp.PostRank <= 5 -- Get the top 5 recent posts for each user
GROUP BY 
    c.UserId, c.DisplayName, c.TotalBountyGiven, c.TotalQuestions, c.TotalComments, c.EditCount, c.CloseCount, c.PopularTagCount
ORDER BY 
    c.TotalBountyGiven DESC, c.TotalQuestions DESC;
