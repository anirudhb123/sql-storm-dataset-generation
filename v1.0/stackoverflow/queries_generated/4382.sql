WITH UserVoteCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM Votes
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        COALESCE(ph.UserDisplayName, 'Community User') AS LastEditor,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.LastEditorUserId = ph.UserId AND p.Id = ph.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.LastActivityDate, ph.UserDisplayName
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.LastActivityDate,
        ps.CommentCount,
        ps.TotalBounty,
        ROW_NUMBER() OVER (ORDER BY ps.TotalBounty DESC, ps.LastActivityDate DESC) AS PopularityRank
    FROM PostStatistics ps
    WHERE ps.CommentCount > 5
)
SELECT 
    pp.Title,
    pp.PostId,
    pp.TotalBounty,
    pp.CommentCount,
    uvc.TotalUpvotes,
    uvc.TotalDownvotes,
    pp.LastEditor,
    pp.PopularityRank
FROM PopularPosts pp
LEFT JOIN UserVoteCounts uvc ON pp.PostId = uvc.UserId
WHERE pp.PopularityRank <= 10
ORDER BY pp.TotalBounty DESC, pp.CommentCount DESC;
