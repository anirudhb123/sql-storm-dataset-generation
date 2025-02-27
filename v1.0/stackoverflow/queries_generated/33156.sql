WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId  -- Join to find answers to questions
    WHERE 
        p.PostTypeId = 2 AND p.AcceptedAnswerId IS NULL  -- Only keep answers that are not accepted
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountySpent,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  -- Count votes only (upvotes and downvotes)
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.VoteCount, 0) AS VoteCount,
        string_agg(DISTINCT t.TagName, ', ') AS Tags,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])  -- Assuming Tags is a CSV of Tag Ids
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Last year posts
    GROUP BY 
        p.Id
),
FinalMetrics AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        up.TotalBountySpent,
        up.TotalPosts,
        up.TotalViews,
        pm.Id AS PostId,
        pm.Title,
        pm.ViewCount,
        pm.CommentCount,
        pm.VoteCount,
        pm.Tags
    FROM 
        UserReputation up
    INNER JOIN 
        Posts pm ON up.UserId = pm.OwnerUserId
    INNER JOIN 
        RecursivePostHierarchy rph ON pm.Id = rph.PostId
)
SELECT 
    UserId,
    DisplayName,
    TotalBountySpent,
    TotalPosts,
    TotalViews,
    PostId,
    Title,
    ViewCount,
    CommentCount,
    VoteCount,
    Tags
FROM 
    FinalMetrics
ORDER BY 
    TotalViews DESC,
    TotalPosts DESC
LIMIT 100;

