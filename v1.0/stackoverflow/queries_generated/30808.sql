WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS ActivityRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM Tags t
    JOIN Posts pt ON t.Id = pt.Tags::text::int[] -- Assuming Tags stored in array
    WHERE pt.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.ViewCount AS RecentPostViewCount,
    tt.TagName
FROM UserActivity ua
LEFT JOIN RecentPosts rp ON ua.UserId = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN TopTags tt ON tt.PostCount > 5 -- Filter for more popular tags
WHERE ua.Reputation > 1000
  AND ua.ActivityRank <= 10
ORDER BY ua.Reputation DESC, rp.ViewCount DESC;
