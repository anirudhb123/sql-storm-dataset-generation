WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
    AND u.CreationDate < NOW() - INTERVAL '1 year'  -- Users with at least 1 year of activity
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Sum of upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes  -- Sum of downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days' 
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        STRING_AGG(DISTINCT ph.UserDisplayName) AS Editors,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 10)  -- Editing title, body, or post closure
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
CombinedData AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        ap.PostId,
        ap.Title,
        ap.ViewCount,
        ap.CommentCount,
        ap.UpVotes,
        ap.DownVotes,
        phi.ChangeCount,
        phi.Editors,
        phi.LastEditDate
    FROM RankedUsers up
    JOIN ActivePosts ap ON up.UserId = ap.OwnerUserId -- Hypothetical ownership relation
    LEFT JOIN PostHistoryAnalysis phi ON ap.PostId = phi.PostId
)
SELECT 
    UserId,
    DisplayName,
    COUNT(PostId) AS TotalPosts,
    SUM(ViewCount) AS TotalViews,
    SUM(CommentCount) AS TotalComments,
    SUM(UpVotes) - SUM(DownVotes) AS NetVotes,
    MAX(LastEditDate) AS LastModified,
    STRING_AGG(DISTINCT Editors) AS EditorList,
    CASE 
        WHEN TotalPosts > 0 THEN 'Active Contributor'
        ELSE 'Inactive'
    END AS UserStatus
FROM CombinedData
GROUP BY UserId, DisplayName
HAVING SUM(ViewCount) > 100 -- Only include users with posts that have more than 100 views
ORDER BY UserRank, TotalPosts DESC NULLS LAST;
