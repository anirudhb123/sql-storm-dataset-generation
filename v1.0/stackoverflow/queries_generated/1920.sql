WITH RankedUsers AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Location,
        RANK() OVER (ORDER BY u.Reputation DESC) as UserRank
    FROM Users u
    WHERE u.Reputation > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
),
RecentPostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),
UserPostAnalytics AS (
    SELECT 
        r.DisplayName,
        r.Reputation,
        COALESCE(rp.PostCount, 0) as RecentPostCount,
        COALESCE(rp.UpVotesCount, 0) as TotalUpVotes,
        COALESCE(rp.DownVotesCount, 0) as TotalDownVotes,
        COALESCE(rp.AvgViewCount, 0) as AvgViewCount,
        CASE 
            WHEN r.UserRank <= 10 THEN 'Top User' 
            ELSE 'Regular User' 
        END as UserTier
    FROM RankedUsers r
    LEFT JOIN RecentPostStats rp ON r.UserId = rp.OwnerUserId
)
SELECT 
    upa.DisplayName,
    upa.Reputation,
    upa.RecentPostCount,
    upa.TotalUpVotes,
    upa.TotalDownVotes,
    upa.AvgViewCount,
    pt.TagName,
    CASE WHEN pt.QuestionCount > pt.AnswerCount THEN 'More Questions' ELSE 'More Answers' END AS TagDominance
FROM UserPostAnalytics upa
JOIN PopularTags pt ON pt.TagName IN (
    SELECT unnest(string_to_array(upa.Tags, ','))
)
ORDER BY upa.Reputation DESC, pt.QuestionCount DESC
FETCH FIRST 100 ROWS ONLY;

