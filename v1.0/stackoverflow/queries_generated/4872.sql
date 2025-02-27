WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS TotalPosts,
        COALESCE(SUM(c.Score), 0) AS TotalComments,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalBounties,
        TotalPosts,
        TotalComments,
        UserRank
    FROM UserStatistics
    WHERE UserRank <= 10
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments WHERE PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes WHERE PostId = p.Id AND VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE (p.PostTypeId = 1 OR p.PostTypeId = 2) AND p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
)
SELECT 
    tu.DisplayName,
    tu.TotalBounties,
    pd.Title,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    CASE 
        WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
        WHEN pd.UpVotes < pd.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment
FROM TopUsers tu
JOIN PostDetail pd ON tu.UserId = pd.OwnerDisplayName
ORDER BY tu.TotalBounties DESC, pd.CreationDate DESC;
