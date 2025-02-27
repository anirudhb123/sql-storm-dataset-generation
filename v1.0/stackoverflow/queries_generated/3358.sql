WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ubc.GoldCount,
        ubc.SilverCount,
        ubc.BronzeCount,
        ROW_NUMBER() OVER(ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadgeCounts ubc ON u.Id = ubc.UserId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.GoldCount,
    tu.SilverCount,
    tu.BronzeCount,
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    CASE 
        WHEN pd.RecentPostRank = 1 THEN 'Most Recent'
        ELSE 'Older Post'
    END AS PostStatus
FROM TopUsers tu
JOIN PostDetails pd ON tu.UserId = pd.OwnerUserId
WHERE 
    tu.UserRank <= 10
    AND pd.Score > (SELECT AVG(Score) FROM Posts)
ORDER BY tu.Reputation DESC, pd.Score DESC;
