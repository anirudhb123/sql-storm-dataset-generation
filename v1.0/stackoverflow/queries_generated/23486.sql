WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        u.Id
),
PollutedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Body,
        rt.Name AS ReasonType
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    LEFT JOIN 
        CloseReasonTypes rt ON ph.Comment::int = rt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Posts Closed or Reopened
    AND 
        p.Body IS NOT NULL
),
UserEngagement AS (
    SELECT 
        us.UserId,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT pl.RelatedPostId) AS TotalLinks
    FROM 
        UserStats us
    LEFT JOIN 
        Comments c ON us.UserId = c.UserId
    LEFT JOIN 
        PostLinks pl ON c.PostId = pl.PostId
    GROUP BY 
        us.UserId
),
AggregateData AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalBounties,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        COALESCE(ue.TotalComments, 0) AS TotalComments,
        COALESCE(ue.TotalLinks, 0) AS TotalLinks,
        us.LatestPostDate,
        COUNT(DISTINCT pp.PostId) AS PollutedPostCount
    FROM 
        UserStats us
    LEFT JOIN 
        UserEngagement ue ON us.UserId = ue.UserId
    LEFT JOIN 
        PollutedPosts pp ON pp.PostId IN (
            SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId
        )
    GROUP BY 
        us.UserId
)
SELECT 
    ad.UserId,
    ad.DisplayName,
    ad.Reputation,
    ad.TotalBounties,
    ad.TotalPosts,
    ad.TotalQuestions,
    ad.TotalAnswers,
    ad.TotalComments,
    ad.TotalLinks,
    ad.LatestPostDate,
    ad.PollutedPostCount,
    CASE 
        WHEN ad.TotalBounties > 0 AND ad.PollutedPostCount = 0 THEN 'Active Contributor'
        WHEN ad.TotalBounties = 0 AND ad.TotalPosts > 0 THEN 'Regular User'
        ELSE 'Newcomer or Inactive'
    END AS UserCategory,
    STRING_AGG(DISTINCT rt.Name, ', ') AS CloseReasonSummary
FROM 
    AggregateData ad
LEFT JOIN 
    PollutedPosts pp ON ad.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
LEFT JOIN 
    CloseReasonTypes rt ON pp.ReasonType = rt.Name
GROUP BY 
    ad.UserId, ad.DisplayName, ad.Reputation, ad.TotalBounties, ad.TotalPosts, ad.TotalQuestions, 
    ad.TotalAnswers, ad.TotalComments, ad.TotalLinks, ad.LatestPostDate, ad.PollutedPostCount
ORDER BY 
    ad.Reputation DESC, ad.UserId;

In this query, we perform the following steps:

1. **UserStats CTE**: This collects overall statistics for each user, including total posts, bounties, and their latest post date.
2. **PollutedPosts CTE**: This identifies posts that have been closed or reopened and tracks the reason types associated with those actions.
3. **UserEngagement CTE**: This captures engagement metrics for users, namely the number of comments and linked posts they have.
4. **AggregateData CTE**: This aggregates data from the previous CTEs, including a count of polluted posts associated with each user.
5. **Final SELECT**: The final result set categorizes each user based on their engagement and activity metrics, gives them a user-friendly categorization, and aggregates any close reasons for the polluted posts.

The query demonstrates the use of outer joins, CTEs,
