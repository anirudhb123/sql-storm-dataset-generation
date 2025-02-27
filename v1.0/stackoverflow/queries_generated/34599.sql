WITH RecursiveUserPosts AS (
    -- CTE to retrieve users and their post counts
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName
),
UserActivity AS (
    -- CTE to retrieve the total activity of each user based on votes and comments
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
CombinedUserStats AS (
    -- CTE to combine user post counts and activity
    SELECT
        upr.UserId,
        upr.DisplayName,
        upr.PostCount,
        ua.VoteCount,
        ua.CommentCount,
        ua.TotalViews,
        RANK() OVER (ORDER BY upr.PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY ua.TotalViews DESC) AS ViewRank
    FROM 
        RecursiveUserPosts upr
    JOIN 
        UserActivity ua ON upr.UserId = ua.UserId
),
HighestActivity AS (
    -- CTE to select users with more than a certain number of total views and join with post titles
    SELECT 
        c.UserId, 
        c.DisplayName, 
        c.PostCount, 
        c.VoteCount, 
        c.CommentCount, 
        c.TotalViews, 
        c.PostRank,
        c.ViewRank,
        p.Title
    FROM 
        CombinedUserStats c
    JOIN 
        Posts p ON c.UserId = p.OwnerUserId
    WHERE 
        c.TotalViews > 1000
),
ActivitySummary AS (
    -- CTE to summarize activity by post type
    SELECT
        p.PostTypeId,
        COUNT(*) AS TypeCount,
        SUM(c.CommentCount) AS TotalComments,
        SUM(c.VoteCount) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        CombinedUserStats c ON p.OwnerUserId = c.UserId
    GROUP BY 
        p.PostTypeId
)
-- Final selection with an outer join to include posts without comments or votes
SELECT 
    u.DisplayName,
    COALESCE(h.Title, 'No Posts') AS LastPostTitle,
    COALESCE(s.TypeCount, 0) AS ActivityCount,
    COALESCE(s.TotalComments, 0) AS TotalComments,
    COALESCE(s.TotalVotes, 0) AS TotalVotes
FROM 
    CombinedUserStats u
LEFT JOIN 
    HighestActivity h ON u.UserId = h.UserId
LEFT JOIN 
    ActivitySummary s ON h.PostTypeId = s.PostTypeId 
WHERE 
    u.TotalViews > 500
ORDER BY 
    u.TotalViews DESC, 
    u.PostCount DESC;
