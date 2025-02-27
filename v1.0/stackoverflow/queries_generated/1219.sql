WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.UserId END) AS CloseCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.UserId END) AS ReopenCount,
        PARENT.Id AS ParentPostId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Posts AS PARENT ON p.ParentId = PARENT.Id
    GROUP BY 
        p.Id, p.Title, PARENT.Id
)
SELECT 
    uvs.DisplayName,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.CloseCount) AS TotalClosures,
    SUM(ps.ReopenCount) AS TotalReopens,
    AVG(uvs.UpVotes - uvs.DownVotes) AS AverageVoteDifference,
    COUNT(DISTINCT CASE WHEN ps.ParentPostId IS NOT NULL THEN ps.PostId END) AS TotalChildPosts,
    STRING_AGG(DISTINCT p.Title, ', ') AS RelatedPostTitles
FROM 
    UserVoteStats uvs
LEFT JOIN 
    PostStats ps ON ps.PostId IN (SELECT RelatedPostId FROM PostLinks pl WHERE pl.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = uvs.UserId))
GROUP BY 
    uvs.DisplayName
HAVING 
    COUNT(ps.PostId) > 5
ORDER BY 
    AverageVoteDifference DESC
LIMIT 10;
