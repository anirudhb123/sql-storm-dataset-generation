WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score > 0 -- Only Questions with a score
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        UserReputation ur
    LEFT JOIN RankedPosts rp ON ur.UserId = rp.OwnerUserId
    GROUP BY 
        ur.UserId, ur.Reputation
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(up.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(dn.TotalDownVotes, 0) AS TotalDownVotes,
    tu.TotalViews,
    tu.TotalScore,
    CASE 
        WHEN tu.TotalScore > 100 THEN 'Gold Member'
        WHEN tu.TotalScore BETWEEN 50 AND 100 THEN 'Silver Member'
        ELSE 'Regular Member' 
    END AS MembershipStatus
FROM 
    Users u
LEFT JOIN UserReputation up ON u.Id = up.UserId
LEFT JOIN UserReputation dn ON u.Id = dn.UserId
LEFT JOIN TopUsers tu ON u.Id = tu.UserId
WHERE 
    u.CreationDate < NOW() - INTERVAL '1 year'
    AND (tu.TotalViews IS NOT NULL OR tu.TotalScore IS NOT NULL)
ORDER BY 
    tu.TotalScore DESC NULLS LAST,
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional query to demonstrate complex predicates 
WITH ClosedPosts AS (
    SELECT 
        p.Id,
        COUNT(pc.Id) AS CloseCount,
        MAX(CASE WHEN pc.Comment IS NOT NULL THEN 1 ELSE 0 END) AS HasCloseReason
    FROM 
        Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        p.Id
)
SELECT 
    p.Title,
    cp.CloseCount,
    CASE 
        WHEN cp.CloseCount > 0 THEN 'Closed Post'
        ELSE 'Active Post' 
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN ClosedPosts cp ON p.Id = cp.Id
WHERE 
    p.CreationDate > NOW() - INTERVAL '6 months'
    AND (cp.HasCloseReason = 0 OR cp.CloseCount IS NULL)
ORDER BY 
    p.CreationDate DESC;
