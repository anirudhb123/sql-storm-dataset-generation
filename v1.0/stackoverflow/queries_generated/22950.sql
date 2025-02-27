WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(u.Reputation) OVER () AS AvgReputation,
        MAX(u.LastAccessDate) AS LastActive
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > COALESCE((SELECT AVG(Reputation) FROM Users), 0)
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounty,
        LastActive,
        RANK() OVER (ORDER BY TotalBounty DESC) AS Rank
    FROM UserActivity
    WHERE PostCount > 5 AND LastActive >= NOW() - INTERVAL '1 year'
),
ClosedPostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UserDisplayName AS ClosedBy,
        ph.CreationDate AS ClosedDate,
        ph.Comment
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalBounty,
    cpd.PostId,
    cpd.Title,
    cpd.ClosedBy,
    cpd.ClosedDate,
    cpd.Comment
FROM TopUsers tu
LEFT JOIN ClosedPostDetails cpd ON tu.UserId = cpd.ClosedBy
WHERE tu.Rank <= 10
ORDER BY tu.TotalBounty DESC, cpd.ClosedDate DESC NULLS LAST;

-- Additional complex logic for handling edge cases
WITH TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostOccurrence
    FROM Tags t
    LEFT JOIN Posts p ON t.Id = p.Tags::text::jsonb->'tag'
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostOccurrence,
        ROW_NUMBER() OVER (ORDER BY PostOccurrence DESC) AS TagRank
    FROM TagCounts
)
SELECT 
    t.TagName,
    t.PostOccurrence,
    CASE 
        WHEN t.PostOccurrence > 100 THEN 'Very Popular'
        WHEN t.PostOccurrence BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM TopTags t
WHERE t.TagRank <= 10;

-- Further complex joins including handling potential NULLs in a correlated subquery
SELECT 
    u.Id,
    u.DisplayName,
    COALESCE(
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id),
        0
    ) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS UpVotes
FROM Users u
WHERE NOT EXISTS (
    SELECT 1 FROM Posts p WHERE p.OwnerUserId = u.Id AND p.Score < 0
)
ORDER BY CommentCount DESC, UpVotes DESC;

-- The complexity of handling various conditions, ranking, and edge cases through outer joins
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Owner,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    p.CreationDate
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY p.Id, u.DisplayName
HAVING SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) = 0
ORDER BY UpVotes DESC, p.CreationDate DESC;

-- Note: 
-- Treat NULL handling, aggregate conditions with '<>' operators, and bizarre semantics interactions with GROUP BY and ORDER BY.
