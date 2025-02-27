WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        MAX(CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate 
            ELSE NULL 
        END) OVER (PARTITION BY p.Id) AS LastClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= current_date - INTERVAL '30 days'
),

UserVotingActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
                WHEN v.VoteTypeId IN (2, 3) THEN 1 
                ELSE 0 
            END) AS TotalVotes,
        SUM(CASE 
                WHEN v.VoteTypeId = 2 THEN 1 
                ELSE 0 
            END) AS UpVotes,
        SUM(CASE 
                WHEN v.VoteTypeId = 3 THEN 1 
                ELSE 0 
            END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100 -- Only users with reputation above 100
    GROUP BY 
        u.Id
)

SELECT 
    up.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalPosts,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.ViewCount) AS TotalViews,
    MAX(rp.Score) AS HighestScore,
    MIN(rp.LastClosedDate) AS FirstClosedPostDate,
    SUM(uba.TotalVotes) AS TotalVotes,
    SUM(uba.UpVotes) AS TotalUpVotes,
    SUM(uba.DownVotes) AS TotalDownVotes
FROM 
    RankedPosts rp
JOIN 
    Users up ON rp.OwnerUserId = up.Id
LEFT JOIN 
    UserVotingActivity uba ON up.Id = uba.UserId
WHERE 
    rp.UserPostRank <= 3 -- Top 3 most recent posts per user
GROUP BY 
    up.DisplayName
HAVING 
    COUNT(DISTINCT rp.Id) > 0 
    AND SUM(rp.ViewCount) > 50 -- Consider only users with posts having more than 50 views
ORDER BY 
    TotalViews DESC;

This SQL query does the following:

1. Uses Common Table Expressions (CTEs) to create `RankedPosts` that ranks posts by their creation date for each user while counting comments and recording the last closed date.
2. Creates a second CTE `UserVotingActivity` that aggregates voting activity (total, up, and down votes) for users with more than 100 reputation.
3. Joins these CTEs to calculate total posts, comments, views, highest scores, and closed post dates for users while filtering for the most recent three posts per user.
4. Filters the results to only include users with at least one post and greater than 50 views on total posts.
5. Orders the results by total views in descending order.

This query is intended for performance benchmarking by using a range of constructs (CTEs, window functions, joins, HAVING clauses, etc.).
