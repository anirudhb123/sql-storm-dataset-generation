WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVotes FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalComments,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserEngagement
    WHERE 
        PostCount > 0
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1 -- Gold badges
    GROUP BY 
        UserId
),
FinalResults AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.PostCount,
        tu.TotalUpVotes,
        tu.TotalDownVotes,
        tu.TotalComments,
        ub.BadgeCount
    FROM 
        TopUsers tu 
    LEFT JOIN 
        UserBadges ub ON tu.UserId = ub.UserId
)
SELECT 
    *,
    ROUND((TotalUpVotes * 1.0 / NULLIF(TotalComments, 0)), 2) AS UpvoteToCommentRatio,
    CASE 
        WHEN BadgeCount IS NULL THEN 'No Gold Badges'
        ELSE 'Has Gold Badges'
    END AS BadgeStatus
FROM 
    FinalResults
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
