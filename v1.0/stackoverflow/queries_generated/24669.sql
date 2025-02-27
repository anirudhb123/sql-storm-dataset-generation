WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ba.Id) AS BadgeCount,
        SUM(v.VoteTypeId IN (2)) AS UpVotes,
        SUM(v.VoteTypeId IN (3)) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges ba ON u.Id = ba.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId, p.CreationDate, p.Title
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        BadgeCount,
        UserRank
    FROM 
        UserActivity 
    WHERE 
        UserRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.TotalComments,
    rp.HasAcceptedAnswer,
    CASE 
        WHEN tu.Reputation > 1000 THEN 'High Reputation'
        WHEN tu.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    COALESCE((
        SELECT 
            b.Name
        FROM 
            Badges b
        WHERE 
            b.UserId = tu.UserId
        ORDER BY 
            b.Date DESC
        LIMIT 1
    ), 'No Badge') AS LatestBadge
FROM 
    RecentPostActivity rp
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.TotalComments > 5 
ORDER BY 
    rp.CreationDate DESC;

-- Test for outer join cases
SELECT 
    u.DisplayName,
    p.Title,
    phc.Comment AS CloseComment,
    CASE 
        WHEN phc.Comment IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE 
    p.CreationDate < NOW() - INTERVAL '1 year'
ORDER BY 
    u.DisplayName, p.Title;

-- Combining multiple predicates with NULL logic
SELECT 
    DISTINCT u.DisplayName,
    (CASE 
        WHEN p.Title IS NOT NULL AND p.Score IS NULL THEN 'Question without Score'
        WHEN p.Title IS NULL OR p.Body IS NULL THEN 'Incomplete Post'
        ELSE 'Complete Post'
    END) AS PostStatus
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    (p.Score IS NOT NULL OR p.Score IS NULL)
    AND (u.Reputation > 0 OR u.Location IS NOT NULL);
