WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.IsAccepted THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS Rnk
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id
),
TopActivityPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CommentCount,
        pa.UpVoteCount,
        pa.DownVoteCount
    FROM PostActivity pa
    WHERE pa.Rnk = 1
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.QuestionCount,
        us.AcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM UserPostStats us
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AcceptedAnswers,
    tp.Title,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount
FROM TopUsers tu
LEFT JOIN TopActivityPosts tp ON tu.UserId = tp.OwnerUserId
WHERE tu.UserRank <= 10
ORDER BY tu.UserRank;
