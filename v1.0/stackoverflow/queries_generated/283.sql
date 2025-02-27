WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.UpVotes,
        us.DownVotes,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 1000
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorId,
        ph.CreationDate AS EditedDate,
        ct.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes ct ON ph.Comment = CAST(ct.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    pu.UserRank,
    pu.DisplayName AS UserDisplayName,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    COALESCE(cpd.CloseReason, 'Not Closed') AS PostCloseReason,
    pu.UpVotes,
    pu.DownVotes
FROM 
    TopUsers pu
JOIN 
    RankedPosts rp ON pu.UserId = rp.OwnerUserId
LEFT JOIN 
    ClosedPostDetails cpd ON rp.PostId = cpd.PostId
WHERE 
    rp.PostRank <= 3
ORDER BY 
    pu.UserRank, rp.Score DESC;
