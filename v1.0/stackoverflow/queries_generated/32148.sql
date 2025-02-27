WITH RecursiveUserHierarchy AS (
    SELECT 
        Id AS UserId,
        Reputation,
        DisplayName,
        CreationDate,
        CAST(NULL AS int) AS ParentId
    FROM Users
    WHERE Reputation > 500

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        r.UserId
    FROM Users u
    INNER JOIN RecursiveUserHierarchy r ON u.Reputation < r.Reputation
    WHERE u.Id != r.UserId
),
TopTags AS (
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.Id, t.TagName
    ORDER BY TotalViews DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE b.Class = 1 -- Gold Badges
    GROUP BY u.Id, u.DisplayName
),
PostsCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, u.DisplayName, p.CreationDate, p.AcceptedAnswerId
)
SELECT 
    p.PostId,
    p.Title,
    p.Author,
    p.CreationDate,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    tair.TagName AS TopTag,
    ub.BadgeCount,
    COALESCE(uh.Reputation, 0) AS ParentReputation
FROM PostsCTE p
LEFT JOIN TopTags tair ON p.CommentCount > 2
LEFT JOIN UserBadges ub ON p.Author = ub.DisplayName
LEFT JOIN RecursiveUserHierarchy uh ON uh.UserId = p.PostId
WHERE 
    p.UpVotes - p.DownVotes > 0
ORDER BY 
    p.CommentCount DESC,
    p.UpVotes DESC
LIMIT 50;
