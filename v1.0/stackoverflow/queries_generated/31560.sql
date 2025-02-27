WITH RECURSIVE UserHierarchy AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        Location,
        0 AS Level
    FROM Users
    WHERE Id = (SELECT MIN(Id) FROM Users) -- arbitrarily chosen root user

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Location,
        uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Reputation < uh.Reputation
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- posts in the last year
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

UserPostScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(pd.Score) AS TotalScore,
        COUNT(pd.PostId) AS PostCount,
        SUM(pd.CommentCount) AS TotalComments,
        SUM(pd.TotalBounty) AS BountyReceived
    FROM Users u
    LEFT JOIN PostDetails pd ON u.Id = pd.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        PostCount,
        TotalComments,
        BountyReceived,
        RANK() OVER (ORDER BY TotalScore DESC) AS UserRank
    FROM UserPostScore
    WHERE TotalScore > 0 -- exclude users with no posts
),

FinalOutput AS (
    SELECT 
        uh.Id AS UserId,
        uh.DisplayName,
        uh.Reputation,
        uh.CreationDate,
        uh.LastAccessDate,
        uh.Location,
        tu.UserRank,
        tu.TotalScore,
        tu.PostCount,
        tu.TotalComments,
        tu.BountyReceived
    FROM UserHierarchy uh
    FULL OUTER JOIN TopUsers tu ON uh.Id = tu.UserId
    WHERE uh.Level < 5 -- filter to show only top levels in hierarchy
)

SELECT 
    *,
    COALESCE(tu.UserRank, 'N/A') AS UserRank,
    CASE WHEN tu.BountyReceived IS NULL THEN 0 ELSE tu.BountyReceived END AS BountyReceived,
    STRING_AGG(tu.DisplayName, ', ') AS ConnectedUsers
FROM FinalOutput
LEFT JOIN TopUsers tu ON tu.UserRank IS NOT NULL
GROUP BY uh.Id, uh.DisplayName, uh.Reputation, uh.CreationDate, uh.LastAccessDate, uh.Location, tu.UserRank, tu.TotalScore, tu.PostCount, tu.TotalComments
ORDER BY COALESCE(tu.TotalScore, 0) DESC, uh.Reputation DESC;

