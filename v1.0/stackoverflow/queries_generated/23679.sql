WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS Engagements
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostEngagements AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON b.UserId = p.OwnerUserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    AND p.Score IS NOT NULL
    GROUP BY p.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(DISTINCT p.Id) > 5
),
RecentPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pg.ParentId, -1) AS ParentPostId,
        ue.DisplayName AS OwnerName,
        json_agg(DISTINCT t.TagName) AS Tags
    FROM Posts p
    LEFT JOIN Posts pg ON p.ParentId = pg.Id
    LEFT JOIN Users ue ON p.OwnerUserId = ue.Id
    LEFT JOIN LATERAL (SELECT unnest(string_to_array(p.Tags, '<>')) AS TagName) t ON true
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, pg.ParentId, ue.DisplayName
)
SELECT 
    rs.PostId,
    rs.Title,
    rs.CreationDate,
    rs.OwnerName,
    COALESCE(ue.Upvotes, 0) AS UpvoteStats,
    COALESCE(pe.CommentCount, 0) AS TotalComments,
    COALESCE(pe.BadgeCount, 0) AS OwnerBadgeCount,
    COALESCE(pt.PostCount, 0) AS PopularTagCount
FROM RecentPostStatistics rs
LEFT JOIN UserVoteStats ue ON rs.OwnerName = ue.DisplayName
LEFT JOIN PostEngagements pe ON rs.PostId = pe.PostId
LEFT JOIN PopularTags pt ON pt.TagName = ANY(rs.Tags)
WHERE rs.PostId IS NOT NULL
ORDER BY rs.CreationDate DESC
LIMIT 50;
