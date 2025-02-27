WITH UserRankings AS (
    SELECT 
        Id as UserId, 
        DisplayName, 
        Reputation, 
        DENSE_RANK() OVER (ORDER BY Reputation DESC) as Rank 
    FROM Users 
),
PostActivity AS (
    SELECT 
        p.Id as PostId,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), NULL) AS ClosedDate,
        COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END), NULL) AS DeletedDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.OwnerUserId, p.CreationDate
),
ActiveUsers AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT pa.PostId) as ActivePostCount,
        AVG(COALESCE(pa.CommentCount, 0)) as AvgCommentCount
    FROM Users u
    JOIN PostActivity pa ON u.Id = pa.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostInsights AS (
    SELECT 
        pa.PostId,
        pa.CommentCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        pa.ClosedDate,
        pa.DeletedDate,
        ROW_NUMBER() OVER (ORDER BY pa.UpVoteCount DESC, pa.CommentCount DESC) as PostRank
    FROM PostActivity pa
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Rank,
    au.ActivePostCount,
    au.AvgCommentCount,
    pi.PostId,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    CASE 
        WHEN pi.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN pi.DeletedDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END as PostStatus
FROM UserRankings ur
LEFT JOIN ActiveUsers au ON ur.UserId = au.UserId
LEFT JOIN PostInsights pi ON au.UserId = pi.OwnerUserId
WHERE ur.Rank <= 100
      AND au.ActivePostCount > 0
ORDER BY ur.Rank, pi.UpVoteCount DESC;

WITH FeaturedTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS RelatedPosts
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 10
),
TagInsights AS (
    SELECT 
        ft.TagName,
        ft.PostCount,
        ft.RelatedPosts,
        COALESCE(ROUND(AVG(u.Reputation), 2), 0) AS AvgUserReputation
    FROM FeaturedTags ft
    LEFT JOIN Users u ON ft.TagName IN (SELECT UNNEST(string_to_array(p.Tags, '><')) FROM Posts p WHERE p.Tags IS NOT NULL)
    GROUP BY ft.TagName, ft.PostCount, ft.RelatedPosts
)
SELECT 
    ti.TagName,
    ti.PostCount,
    ti.RelatedPosts,
    ti.AvgUserReputation,
    CASE 
        WHEN ti.AvgUserReputation > 1000 THEN 'Popular Tag'
        ELSE 'Niche Tag'
    END as TagCategory
FROM TagInsights ti
ORDER BY ti.PostCount DESC, ti.AvgUserReputation DESC;
