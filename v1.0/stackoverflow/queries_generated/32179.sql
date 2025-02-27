WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

UserVoteSummary AS (
    SELECT 
        v.UserId,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),

TagsWithPostCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),

ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS ClosedDate,
        COALESCE(p.Body, '') AS PostBody,
        COALESCE(u.DisplayName, 'Unknown') AS ClosedBy
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
),

UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold Badges
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    us.TotalVotes,
    us.Upvotes,
    us.Downvotes,
    COALESCE(ub.BadgeCount, 0) AS GoldBadges,
    COALESCE(tc.PostCount, 0) AS TotalTags,
    ARRAY_AGG(DISTINCT t.TagName) AS TagNames,
    ARRAY_AGG(DISTINCT p.Title ORDER BY p.LastActivityDate DESC) AS RecentPostTitles,
    ARRAY_AGG(DISTINCT cp.ClosedPostId) AS ClosedPostIds,
    COUNT(DISTINCT r.Id) AS AnsweredPosts,
    SUM(CASE WHEN r.Level = 0 THEN 1 ELSE 0 END) AS TopLevelQuestions
FROM 
    Users u
LEFT JOIN 
    UserVoteSummary us ON u.Id = us.UserId
LEFT JOIN 
    TagsWithPostCounts tc ON u.Id = tc.TagId
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    ClosedPosts cp ON cp.ClosedPostId = p.Id
LEFT JOIN 
    RecursivePostHierarchy r ON r.Id = p.Id
LEFT JOIN 
    UserBadgeCounts ub ON ub.UserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC, us.TotalVotes DESC
LIMIT 100
OFFSET 0;
