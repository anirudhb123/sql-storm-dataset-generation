
WITH UserTagStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS TagsContributed
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            pt.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM Posts p
        CROSS JOIN (
            SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
        ) numbers
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        AND p.PostTypeId = 1
    ) t ON p.Id = t.Id
    GROUP BY u.Id, u.DisplayName
),
RecentlyClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
),
TopUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS PositiveVotes
    FROM Votes
    GROUP BY UserId
    ORDER BY TotalVotes DESC
    LIMIT 10
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    ut.TotalPosts,
    ut.TotalQuestions,
    ut.TotalAnswers,
    ut.AcceptedAnswers,
    ut.TagsContributed,
    rcp.PostId,
    rcp.Title AS ClosedPostTitle,
    rcp.ClosedDate,
    rcp.ClosedBy,
    rcp.CloseReason,
    tu.TotalVotes,
    tu.PositiveVotes
FROM UserTagStats ut
JOIN Users u ON u.Id = ut.UserId
LEFT JOIN RecentlyClosedPosts rcp ON TRUE 
JOIN TopUsers tu ON u.Id = tu.UserId
ORDER BY rcp.ClosedDate DESC, u.Reputation DESC;
