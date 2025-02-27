
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_owner_user_id := p.OwnerUserId,
        p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        ur.Reputation,
        COALESCE(uq.CloseCount, 0) AS CloseCount,
        CASE 
            WHEN COALESCE(uq.CloseCount, 0) > 0 THEN 'Closed'
            ELSE 'Active'
        END AS Status
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        ClosedQuestions uq ON rp.Id = uq.PostId
    WHERE 
        rp.PostRank = 1 
)
SELECT 
    pd.Title,
    pd.Reputation,
    pd.Status,
    COUNT(c.Id) AS CommentCount
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.Id = c.PostId
WHERE 
    pd.Reputation > 1000 
GROUP BY 
    pd.Title, pd.Reputation, pd.Status
ORDER BY 
    pd.Reputation DESC, pd.Title ASC;
