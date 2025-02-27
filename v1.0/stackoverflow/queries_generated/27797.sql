WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS PostHistoryCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
UserTagStatistics AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        pt.TagName,
        COUNT(pt.TagName) AS TagFrequency
    FROM UserStatistics us
    JOIN Posts p ON us.UserId = p.OwnerUserId
    JOIN LATERAL unnest(string_to_array(p.Tags, '>')) AS tag(pt.TagName) ON TRUE
    WHERE pt.TagName IN (SELECT TagName FROM PopularTags)
    GROUP BY us.UserId, us.DisplayName, pt.TagName
),
FinalReport AS (
    SELECT 
        uts.UserId,
        uts.DisplayName,
        uts.TagName,
        uts.TagFrequency,
        us.Reputation,
        us.PostCount,
        us.UpVotes,
        us.DownVotes,
        us.BadgeCount,
        us.CommentCount,
        us.PostHistoryCount
    FROM UserTagStatistics uts
    JOIN UserStatistics us ON uts.UserId = us.UserId
)
SELECT 
    UserId,
    DisplayName,
    TagName,
    TagFrequency,
    Reputation,
    PostCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    CommentCount,
    PostHistoryCount
FROM FinalReport
ORDER BY TagFrequency DESC, Reputation DESC;
