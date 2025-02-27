WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN COALESCE(v.VoteTypeId, 0) = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN COALESCE(v.VoteTypeId, 3) = 1 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopPostOwners AS (
    SELECT 
        u.DisplayName, 
        us.Reputation, 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserStats us ON u.Id = us.UserId
    WHERE 
        rp.RowNum = 1
)
SELECT 
    tpo.DisplayName,
    tpo.Reputation,
    tpo.Title,
    tpo.CreationDate,
    tpo.Score,
    COALESCE(ph.CloseReasonTypes, 'No close reason') AS CloseReason
FROM 
    TopPostOwners tpo
LEFT JOIN 
    PostHistory ph ON tpo.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
ORDER BY 
    tpo.Score DESC
