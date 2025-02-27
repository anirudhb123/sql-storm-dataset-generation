WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.OwnerUserId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadgePoints,
        COUNT(v.PostId) AS TotalVotes,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT ph.PostId) AS TotalPostHistory
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
)
SELECT 
    u.DisplayName AS UserName,
    u.TotalBadgePoints,
    u.TotalVotes,
    u.TotalPosts,
    u.TotalPostHistory,
    p.PostTitle,
    p.Score,
    p.ScoreRank,
    t.TagName,
    th.Level AS PostLevel
FROM 
    UserReputationSummary u
JOIN 
    PostScores p ON p.Reputation = u.TotalBadgePoints
JOIN 
    TopTags t ON t.TagName IN (SELECT unnest(string_to_array(p.Tags, '><')))
LEFT JOIN 
    RecursivePostHierarchy th ON th.PostId = p.PostId
WHERE 
    u.TotalPostHistory > 0
ORDER BY 
    u.TotalBadgePoints DESC, 
    p.Score DESC;
