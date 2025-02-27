WITH RecursiveTagCounts AS (
    SELECT
        Tags.Id AS TagId,
        Tags.TagName,
        Tags.Count,
        (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || Tags.TagName || '%') AS PostCount
    FROM 
        Tags
    WHERE Tags.Count > 0
    
    UNION ALL
    
    SELECT
        rc.TagId,
        rc.TagName,
        rc.Count,
        (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || rc.TagName || '%') AS PostCount
    FROM 
        RecursiveTagCounts rc 
    JOIN 
        Tags t ON rc.TagName = t.TagName
    WHERE rc.PostCount < 100 -- limiting recursion for performance
),
FilteredUsers AS (
    SELECT
        u.Id,
        u.Reputation,
        u.DisplayName,
        COALESCE(u.Location, 'Unknown') AS SafeLocation,
        AVG(v.BountyAmount) AS AvgBounty,
        COUNT(b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8,9) -- Only consider bounty start and close
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.Location
    HAVING 
        COUNT(b.Id) > 2 -- Only include users with more than 2 badges
),
PostStat AS (
    SELECT
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.SafeLocation,
    u.Reputation,
    u.AvgBounty,
    u.BadgeCount,
    COALESCE(ps.PostCount, 0) AS TotalPostCount,
    COALESCE(ps.TotalViews, 0) AS TotalPostViews,
    COALESCE(ps.QuestionCount, 0) AS QuestionCount,
    COALESCE(ps.AnswerCount, 0) AS AnswerCount,
    ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY u.Reputation DESC) AS Ranking,
    ttk.TagName AS TopTag
FROM 
    FilteredUsers u
LEFT JOIN 
    PostStat ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    (SELECT TagId, TagName FROM RecursiveTagCounts ORDER BY PostCount DESC LIMIT 1) ttk ON true
WHERE 
    NOT EXISTS (SELECT 1 FROM Comments c WHERE c.UserId = u.Id AND c.Score < 0) -- Users without negative comments
ORDER BY 
    u.Reputation DESC, u.BadgeCount DESC;
