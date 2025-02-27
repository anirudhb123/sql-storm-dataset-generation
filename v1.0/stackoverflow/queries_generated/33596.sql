WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, 1 AS Level
    FROM Users
    WHERE Reputation >= (SELECT AVG(Reputation) FROM Users)
    
    UNION ALL

    SELECT u.Id, u.Reputation, ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation > ur.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id
),
TopUserPosts AS (
    SELECT 
        u.DisplayName,
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CommentCount,
        COALESCE(ur.Level, 0) AS ReputationLevel
    FROM 
        PostDetails p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserReputationCTE ur ON u.Id = ur.Id
    WHERE 
        p.PostRank <= 5
),
FinalResults AS (
    SELECT 
        DisplayName,
        COUNT(PostId) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AverageViews,
        MAX(ReputationLevel) AS HighestReputationLevel
    FROM 
        TopUserPosts
    GROUP BY 
        DisplayName
)
SELECT 
    DisplayName,
    PostCount,
    TotalScore,
    AverageViews,
    CASE 
        WHEN HighestReputationLevel = 0 THEN 'No Reputation' 
        ELSE 'With Reputation' 
    END AS ReputationStatus
FROM 
    FinalResults
ORDER BY 
    TotalScore DESC, PostCount DESC
LIMIT 10;
