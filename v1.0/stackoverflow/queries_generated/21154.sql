WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only Questions
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COUNT(DISTINCT p.Id) AS TotalQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalViews,
    ups.AcceptedAnswers,
    ups.TotalQuestions,
    COALESCE(rp.PostTitle, 'No Recent Posts') AS RecentPost,
    COALESCE(rp.CreationDate, 'N/A') AS RecentPostDate,
    rp.TotalPosts AS NumberOfPostsByUser,
    cr.CloseReasonCount,
    cr.CloseReasons
FROM 
    UserPostStats ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    ups.TotalQuestions > 0
ORDER BY 
    ups.TotalViews DESC, ups.DisplayName ASC
FETCH FIRST 10 ROWS ONLY;

### Query Explanation:
1. **CTEs**:
   - **RankedPosts**: This CTE ranks questions by their creation date for each user over the last year. It utilizes `ROW_NUMBER` and `COUNT` window functions.
   - **UserPostStats**: This aggregates user statistics like total views, accepted answers, and total questions posted.
   - **CloseReasons**: This fetches any closure reasons for posts, counting how many times each post was closed and listing the types of closures.

2. **Final Selection**: The main query retrieves stats for the top users based on question views and combines them with their most recent posts and close reasons.

3. **Complexity**: It employs outer joins, window functions, aggregate functions, and string aggregation to provide detailed insights on user interactions with posts, showcasing intricate SQL constructs and handling NULL values robustly through COALESCE. 

4. **Sorting and Limiting**: Results are sorted by views and limited to the top 10 users, showcasing performance-related logic in the query's construction.
