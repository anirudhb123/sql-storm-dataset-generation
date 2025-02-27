WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, DisplayName, Reputation, 1 AS Level
    FROM Users
    WHERE Reputation > 0
    
    UNION ALL
    
    SELECT u.Id, u.DisplayName, u.Reputation, ur.Level + 1
    FROM Users u
    INNER JOIN UserReputationCTE ur ON u.Reputation < ur.Reputation
    WHERE ur.Level < 3
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ah.Score, 0) AS AcceptedAnswerScore
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Posts ah ON p.AcceptedAnswerId = ah.Id
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

PostVoteSummary AS (
    SELECT
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Votes
    GROUP BY PostId
),

ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.Upvotes) AS TotalUpvotes,
        SUM(v.Downvotes) AS TotalDownvotes,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostVoteSummary v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    ud.DisplayName AS UserName,
    ud.Reputation AS UserReputation,
    pd.PostId,
    pd.Title AS PostTitle,
    pd.CreationDate AS PostCreationDate,
    pd.Score AS PostScore,
    COALESCE(pvs.Upvotes, 0) AS Upvotes,
    COALESCE(pvs.Downvotes, 0) AS Downvotes,
    COALESCE(ud.TotalUpvotes, 0) AS UserTotalUpvotes,
    COALESCE(ud.TotalDownvotes, 0) AS UserTotalDownvotes,
    COALESCE(ud.TotalBounty, 0) AS UserTotalBounty,
    CASE 
        WHEN pd.AcceptedAnswerId != 0 THEN 'Accepted Answer Exists' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus,
    ROW_NUMBER() OVER (PARTITION BY ud.Id ORDER BY pd.CreationDate DESC) AS UserPostOrder
FROM UserReputationCTE ud
JOIN PostDetails pd ON ud.Id = pd.OwnerUserId
LEFT JOIN PostVoteSummary pvs ON pd.PostId = pvs.PostId
JOIN ActiveUsers u ON u.Id = ud.Id
WHERE ud.Level = 1
AND (pvs.Upvotes - pvs.Downvotes) > 5
ORDER BY ud.Reputation DESC, pd.CreationDate DESC;

