WITH RecursiveParentPosts AS (
    -- CTE to recursively fetch parent posts for each post
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        p.Score,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveParentPosts rp ON p.ParentId = rp.Id
),
TopUsers AS (
    -- CTE to find top users with the most reputation
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PostEngagement AS (
    -- CTE to calculate engagement metrics per post
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
PopularTags AS (
    -- CTE to determine popular tags based on the number of associated Posts
    SELECT 
        Tags.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags
    JOIN 
        Posts ON Posts.Tags LIKE CONCAT('%', Tags.TagName, '%')
    GROUP BY 
        Tags.TagName
),
ClosedPosts AS (
    -- CTE to find the posts that have been closed
    SELECT
        ph.PostId,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    pu.DisplayName AS TopUser,
    p.Title AS PostTitle,
    p.ViewCount AS TotalViews,
    p.CommentCount AS TotalComments,
    p.VoteCount AS TotalVotes,
    pt.TagName AS PopularTag,
    cp.CloseCount AS CloseCounts,
    r.Title AS RootPostTitle
FROM 
    PostEngagement p
INNER JOIN 
    TopUsers pu ON p.ViewCount > 100 -- Example threshold for engagement
LEFT JOIN 
    PopularTags pt ON p.Title LIKE '%' || pt.TagName || '%'
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
LEFT JOIN 
    RecursiveParentPosts r ON p.ParentId = r.Id
WHERE 
    pu.ReputationRank <= 10  -- Limiting to top 10 users
ORDER BY 
    TotalVotes DESC, TotalViews DESC
