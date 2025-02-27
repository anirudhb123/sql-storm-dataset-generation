WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadges,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        p.Title,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN TRUE
            ELSE FALSE
        END AS IsClosedOrReopened
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
),
AggregateData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ur.DisplayName,
        ur.Reputation,
        ur.TotalBadges, 
        SUM(CASE WHEN ph.IsClosedOrReopened THEN 1 ELSE 0 END) AS CloseReopenCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.UserPostRank = 1
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    GROUP BY 
        rp.PostId, ur.DisplayName, ur.Reputation, rp.Title
)
SELECT 
    PostId,
    Title,
    CreationDate,
    DisplayName,
    Reputation,
    TotalBadges,
    CloseReopenCount
FROM 
    AggregateData
WHERE 
    CloseReopenCount > 0
ORDER BY 
    CreationDate DESC
LIMIT 10;
