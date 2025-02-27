WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen actions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT ph.Id) AS CloseReopenCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN RecursivePostHistory rph ON p.Id = rph.PostId
    GROUP BY p.Id, p.Title
),
FinalStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.CloseReopenCount,
        CASE 
            WHEN ps.CloseReopenCount > 0 THEN 'Closed/Reopened'
            ELSE 'Active'
        END AS PostStatus,
        ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY ps.CloseReopenCount DESC, ps.UpVoteCount DESC) AS rn
    FROM UserActivity ua
    JOIN PostStats ps ON ua.UserId = ps.PostId  -- Assumes UserId relates to posts indirectly
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.PostId,
    fs.Title,
    fs.CommentCount,
    fs.UpVoteCount,
    fs.DownVoteCount,
    fs.CloseReopenCount,
    fs.PostStatus
FROM FinalStats fs
WHERE fs.rn = 1  -- Get only the most active post per user
ORDER BY fs.UpVoteCount DESC, fs.CloseReopenCount DESC;

This SQL query involves several advanced constructs:
1. **Recursive CTE**: Used to summarize Close and Reopen actions on posts.
2. **Multiple Aggregations**: Count of posts, comments, bounties, and votes for users and posts.
3. **Window Functions**: To rank posts by activity and categorize users.
4. **Outer Joins**: To ensure we include users even if they have no posts or comments.
5. **Complicated CASE Expressions**: To determine the status of a post based on its history.
