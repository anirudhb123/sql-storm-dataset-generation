WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Start from all Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        Level + 1
    FROM Posts p
    JOIN RecursivePostCTE r ON p.ParentId = r.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
RankedUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.PostCount,
        ur.TotalViews,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ur.PostCount DESC, ur.TotalViews DESC) AS Rank
    FROM UserReputation ur
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        r.UserId,
        r.Reputation,
        ROW_NUMBER() OVER (PARTITION BY r.UserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    JOIN RankedUsers r ON p.OwnerUserId = r.UserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        STRING_AGG(crt.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes crt ON ph.Comment::json->>'reasonId'::int = crt.Id
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UserId,
    pd.Reputation,
    pd.UserPostRank,
    COALESCE(cr.CloseCount, 0) AS CloseCount,
    COALESCE(cr.CloseReasonNames, 'None') AS CloseReasonNames,
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2 -- UpMod
    ) AS HasUpVote
FROM PostDetails pd
LEFT JOIN CloseReasons cr ON pd.PostId = cr.PostId
WHERE pd.UserPostRank <= 5  -- Top 5 Posts per User
ORDER BY pd.Reputation DESC, pd.CreationDate DESC;
