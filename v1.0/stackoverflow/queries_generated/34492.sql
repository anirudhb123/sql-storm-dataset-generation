WITH RankedUsers AS (
    SELECT
        Id,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostWithBadges AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        b.Name AS BadgeName,
        b.Class AS BadgeClass
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE p.Score > 0
    AND b.Class IS NOT NULL
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserDisplayName,
        ph.CreationDate AS ClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
PostTags AS (
    SELECT
        p.Title,
        Tags,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM Posts p
    LEFT JOIN (
        SELECT
            PostId,
            UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName
        FROM Posts
    ) t ON p.Id = t.PostId
    GROUP BY p.Id, p.Title
)
SELECT
    ru.DisplayName AS User,
    ru.Reputation AS UserReputation,
    pp.PostId,
    pp.Title AS PostTitle,
    pp.RecentPostRank,
    pb.BadgeName,
    pb.BadgeClass,
    COALESCE(cp.Comment, 'Not Closed') AS ClosureComment,
    COALESCE(cp.ClosedDate, NOW()) AS ClosureDate,
    pt.TagList
FROM 
    RankedUsers ru
LEFT JOIN 
    RecentPosts pp ON ru.Id = pp.OwnerUserId
LEFT JOIN 
    PostWithBadges pb ON pp.PostId = pb.PostId
LEFT JOIN 
    ClosedPosts cp ON pp.PostId = cp.PostId
LEFT JOIN 
    PostTags pt ON pp.PostId = pt.PostId
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.Reputation DESC, pp.RecentPostRank ASC;
