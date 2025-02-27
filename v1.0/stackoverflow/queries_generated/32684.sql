WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(b.Class) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS ClosedDate, 
        ph.UserDisplayName AS ClosedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
TagPostCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.TotalBadges,
    u.TotalPosts,
    u.TotalComments,
    u.AvgPostScore,
    ps.UpVotes,
    ps.DownVotes,
    cpd.ClosedDate,
    cpd.ClosedBy,
    t.TagName, 
    tc.PostCount
FROM 
    RecursivePostHierarchy r
JOIN 
    UserReputationSummary u ON r.PostId IN (SELECT ParentId FROM Posts WHERE ParentId IS NOT NULL)
LEFT JOIN 
    PostVoteSummary ps ON r.PostId = ps.PostId
LEFT JOIN 
    ClosedPostDetails cpd ON r.PostId = cpd.PostId
LEFT JOIN 
    TagPostCounts tc ON r.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%', tc.TagName, '%'))
LEFT JOIN 
    Tags t ON tc.TagId = t.Id
ORDER BY 
    r.CreationDate DESC, 
    u.TotalBadges DESC;
