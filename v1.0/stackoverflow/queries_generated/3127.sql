WITH UserBadgeCounts AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(voteCounts.UpVotes, 0) AS UpVotes,
        COALESCE(voteCounts.DownVotes, 0) AS DownVotes,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.EditCount, 0) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, 
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) voteCounts ON p.Id = voteCounts.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS EditCount
        FROM PostHistory
        WHERE PostHistoryTypeId IN (4, 5, 6)
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
),
PopularTags AS (
    SELECT 
        tag.TagName,
        COUNT(*) AS PostCount
    FROM Tags tag
    JOIN Posts p ON tag.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY tag.TagName
    HAVING COUNT(*) > 10
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN UserBadgeCounts ub ON u.Id = ub.UserId
    WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
)

SELECT 
    u.DisplayName AS UserName,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.UpVotes) AS TotalUpVotes,
    SUM(ps.DownVotes) AS TotalDownVotes,
    SUM(ps.CommentCount) AS TotalComments,
    SUM(ps.EditCount) AS TotalEdits,
    tt.TagName,
    tt.PostCount
FROM TopUsers u
JOIN PostStats ps ON u.Id = ps.OwnerUserId
JOIN PopularTags tt ON ps.Tags LIKE '%' || tt.TagName || '%'
GROUP BY u.DisplayName, tt.TagName
ORDER BY TotalPosts DESC, TotalUpVotes DESC
LIMIT 10;
