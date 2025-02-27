WITH RankedUsers AS (
    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        u.LastAccessDate,
        u.WebsiteUrl,
        u.Location,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        u.ProfileImageUrl,
        u.EmailHash,
        u.AccountId,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN u.Reputation >= 1000 THEN 'high' ELSE 'low' END ORDER BY u.CreationDate DESC) AS UserRank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(CAST(p.Score AS FLOAT), 0)) AS AvgScore
    FROM Posts p
    GROUP BY p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Title,
        p.CreationDate,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        CASE
            WHEN p.Score < 0 THEN 'Unpopular'
            WHEN p.Score BETWEEN 0 AND 5 THEN 'Moderately Popular'
            ELSE 'Popular'
        END AS Popularity
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(p.Tags, '><')) AS TagName
    ) t ON TRUE
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.PostTypeId, p.Title, p.CreationDate, p.Score
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastAwarded
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '6 months'
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalPosts,
    ps.QuestionCount,
    ps.AnswerCount,
    ps.AvgScore,
    fp.PostId,
    fp.Title,
    fp.Popularity,
    rb.BadgeCount,
    rb.LastAwarded,
    CASE 
        WHEN fp.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM RankedUsers u
LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN FilteredPosts fp ON u.Id = fp.OwnerUserId
LEFT JOIN RecentBadges rb ON u.Id = rb.UserId
WHERE u.Reputation > 500
ORDER BY u.Reputation DESC, ps.TotalPosts DESC, fp.Popularity DESC
LIMIT 100
OFFSET 0;
This SQL query is designed for performance benchmarking, employing a variety of complex constructs such as CTEs, window functions, outer joins, and conditional aggregations. It retrieves data about users, their posts, comments, badges, and calculates user engagement levels while utilizing advanced SQL semantics.
