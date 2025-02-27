WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(b.Class) AS TotalBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.UpVotes, u.DownVotes
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, pt.Name
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM UserStatistics us
    WHERE us.TotalPosts > 10
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS PostRank
    FROM PostDetails pd
    WHERE pd.CommentCount > 5
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tp.PostId,
    tp.Title AS PostTitle,
    tp.ViewCount AS PostViewCount,
    tu.UserRank,
    tp.PostRank
FROM TopUsers tu
JOIN TopPosts tp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY tu.UserRank, tp.PostRank;
