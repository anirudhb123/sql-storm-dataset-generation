WITH RecursiveUserVotes AS (
    SELECT 
        v.UserId,
        v.PostId,
        v.VoteTypeId,
        u.Reputation,
        COUNT(*) OVER (PARTITION BY v.UserId) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY v.UserId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM Votes v
    JOIN Users u ON v.UserId = u.Id
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Badges b
    GROUP BY b.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        COALESCE(pc.VoteCount, 0) AS VoteCount,
        COALESCE(cm.CommentCount, 0) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        STUFF((SELECT ', ' + t.TagName
               FROM Tags t 
               WHERE t.WikiPostId = p.Id
               FOR XML PATH('')), 1, 2, '') AS Tags
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) cm ON p.Id = cm.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId 
    GROUP BY p.Id, p.Score
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ub.BadgeCount,
        ub.BadgeNames,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation IS NOT NULL
)
SELECT 
    pu.DisplayName,
    pu.Reputation,
    pu.BadgeCount,
    pu.BadgeNames,
    ps.PostId,
    ps.Score,
    ps.VoteCount,
    ps.CommentCount,
    ps.RelatedPostCount,
    ps.Tags,
    CASE 
        WHEN ps.Score IS NULL THEN 'No score'
        ELSE CASE 
            WHEN ps.Score > 0 THEN 'Positive'
            WHEN ps.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END 
    END AS ScoreStatus,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM RecursiveUserVotes rv 
            WHERE rv.UserId = pu.UserId AND rv.VoteRank = 1
        ) THEN 'Voted Recently'
        ELSE 'No recent vote'
    END AS RecentVotingActivity
FROM PostStatistics ps
JOIN TopUsers pu ON ps.PostId IN (SELECT PostId FROM Votes WHERE UserId = pu.UserId)
WHERE pu.UserRank <= 10
ORDER BY pu.Reputation DESC, ps.Score DESC;
