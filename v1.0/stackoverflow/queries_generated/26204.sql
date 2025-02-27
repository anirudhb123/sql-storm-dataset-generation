WITH TopUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Only bounty-related votes
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  -- Tag matching
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY t.TagName
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title
    ORDER BY Upvotes DESC 
    LIMIT 10
)
SELECT 
    u.DisplayName AS TopUser,
    t.TagName AS PopularTag,
    tq.Title AS TopQuestion,
    tq.LastEditDate,
    tq.CommentCount,
    tq.Upvotes,
    tu.TotalBounties,
    tu.TotalPosts,
    tu.TotalBadges
FROM TopUsers tu
CROSS JOIN (
    SELECT TagName FROM TopTags ORDER BY PostCount DESC LIMIT 5
) t
CROSS JOIN TopQuestions tq
ORDER BY tu.TotalBounties DESC, tq.Upvotes DESC;

