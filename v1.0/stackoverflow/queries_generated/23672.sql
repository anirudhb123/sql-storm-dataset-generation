WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsParticipated
    FROM Users u
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id
), 
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Comment, 'No Comments') AS LastEditComment,
        DENSE_RANK() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory
        WHERE PostId = p.Id
    )
)
SELECT 
    u.Id, 
    u.DisplayName,
    u.Reputation,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.LastEditComment,
    p.TotalComments,
    uvs.UpVotes,
    uvs.DownVotes,
    CASE 
        WHEN p.EditRank = 1 THEN 'Recent Edit'
        ELSE 'Older Edit'
    END AS EditStatus
FROM Users u
JOIN UserVoteStats uvs ON u.Id = uvs.UserId
LEFT JOIN PostInteraction p ON p.TotalComments > 0
WHERE u.Reputation >= 100 AND (
    SELECT COUNT(*) 
    FROM Badges b 
    WHERE b.UserId = u.Id AND b.Class = 1
) > 0  -- Must be Gold badge holders
ORDER BY 
    COALESCE(uvs.UpVotes, 0) - COALESCE(uvs.DownVotes, 0) DESC, 
    p.CreationDate DESC 
LIMIT 50;

-- Note: This query performs the following:
-- 1. It calculates user vote statistics, including upvotes and downvotes.
-- 2. It retrieves recent post edits along with the latest comment or 'No Comments'.
-- 3. It fetches users with a reputation of 100 or more who have a gold badge.
-- 4. It ranks posts based on upvotes minus downvotes and displays them accordingly.
-- 5. It includes elaborate use of subqueries, CTEs, window functions, and conditional logic.
