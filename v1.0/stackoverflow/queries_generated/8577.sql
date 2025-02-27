WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikis,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        MAX(u.CreationDate) AS AccountCreationDate,
        MAX(u.LastAccessDate) AS LastAccess
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        TagWikis, 
        UpVotes, 
        DownVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM UserStats
    WHERE TotalPosts > 0
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.Questions,
    t.Answers,
    t.TagWikis,
    t.UpVotes,
    t.DownVotes,
    TO_CHAR(age(t.AccountCreationDate), 'YY years, MM months, DD days') AS AccountAge,
    TO_CHAR(age(t.LastAccess), 'YY years, MM months, DD days') AS LastActiveDuration
FROM TopUsers t
WHERE t.PostRank <= 10
ORDER BY t.PostRank;
