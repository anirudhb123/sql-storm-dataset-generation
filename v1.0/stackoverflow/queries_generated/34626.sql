WITH RecursivePostHierarchy AS (
    -- Recursively get all parent posts for a given post
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
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
        Level + 1
    FROM 
        Posts p
    JOIN RecursivePostHierarchy rph ON p.ParentId = rph.Id
),
UserActivity AS (
    -- Calculate user activity including votes, comments, and post counts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(c.Score) AS CommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    -- Fetch top users based on the number of posts created
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        VoteCount,
        UpVotes,
        DownVotes,
        CommentScore,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserActivity
),
PostSummary AS (
    -- Aggregate post statistics including answer and comment count along with recent activity
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COALESCE(d.RecentComments, 0) AS RecentComments
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RecentComments
        FROM 
            Comments
        WHERE 
            CreationDate >= NOW() - INTERVAL '30 days'
        GROUP BY 
            PostId
    ) d ON p.Id = d.PostId
),
TagStatistics AS (
    -- Calculate tag statistics such as usage count and the most recent post
    SELECT 
        t.TagName,
        t.Count AS UsageCount,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName, t.Count
)
SELECT 
    pu.DisplayName AS TopUserName,
    pu.PostCount AS TotalPosts,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.AnswerCount AS TotalAnswers,
    ps.CommentCount AS TotalComments,
    ts.TagName AS PopularTag,
    ts.UsageCount AS TagUsage,
    ts.LatestPostDate AS TagLatestPostDate
FROM 
    TopUsers pu
JOIN 
    PostSummary ps ON pu.PostCount > 0
JOIN 
    TagStatistics ts ON ts.UsageCount > 10
WHERE 
    pu.Rank <= 10  -- Limit to top 10 users
ORDER BY 
    pu.PostCount DESC,
    ts.UsageCount DESC;

