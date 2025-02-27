WITH UserVoteDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVotes,
        AVG(p.Score) OVER (PARTITION BY p.OwnerUserId) AS AvgScorePerUser,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATEADD(month, -12, GETDATE())
      AND 
        (p.PostTypeId = 1 OR p.PostTypeId = 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        MAX(ps.AvgScorePerUser) AS MaxAvgScore
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        RANK() OVER (ORDER BY ua.TotalUpVotes - ua.TotalDownVotes DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    ru.DisplayName,
    ru.TotalPosts,
    ru.TotalComments,
    ru.TotalUpVotes,
    ru.TotalDownVotes,
    CASE 
        WHEN ru.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus,
    uvd.TotalUpvotes,
    uvd.TotalDownvotes,
    (CASE WHEN uvd.TotalUpvotes > 0 THEN CAST(uvd.TotalDownvotes AS FLOAT) / uvd.TotalUpvotes ELSE NULL END) AS DownvoteToUpvoteRatio
FROM 
    RankedUsers ru
JOIN 
    UserVoteDetails uvd ON ru.UserId = uvd.UserId
WHERE 
    ru.TotalPosts > 5
ORDER BY 
    ru.UserRank;
