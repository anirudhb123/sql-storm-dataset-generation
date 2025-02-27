WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Question posts
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(CASE WHEN p.Score IS NULL THEN 1 ELSE 0 END) AS NullScorePosts,
        COUNT(DISTINCT ph.Id) AS TotalPostHistoryChanges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000  -- filtering users by reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FinalResults AS (
    SELECT 
        uc.UserId,
        uc.DisplayName,
        ph.Title AS PostTitle,
        ph.TotalPosts,
        ph.PositivePosts,
        ph.NegativePosts,
        ps.TotalBountyAmount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY uc.UserId ORDER BY ps.UpVotes DESC) AS Rank
    FROM 
        UserActivity uc
    JOIN 
        PostStatistics ps ON uc.UserId = ps.OwnerUserId
)

SELECT 
    UserId,
    DisplayName,
    PostTitle,
    TotalPosts,
    PositivePosts,
    NegativePosts,
    TotalBountyAmount,
    UpVotes,
    DownVotes,
    CommentCount,
    Rank
FROM 
    FinalResults
WHERE 
    Rank <= 3
ORDER BY 
    TotalPosts DESC, UpVotes DESC, UserId;
