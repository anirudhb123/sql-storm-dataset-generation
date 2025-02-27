WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '60 days'
),
RankedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.TotalBounties,
        ur.Upvotes,
        ur.Downvotes,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Has accepted answer'
        ELSE 'No accepted answer'
    END AS AnswerStatus,
    phd.HistoryType,
    phd.UserDisplayName AS HistoryEditor,
    phd.CreationDate AS HistoryEditDate,
    UsersRank.UserRank,
    UsersRank.TotalBounties
FROM 
    RecentPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId AND phd.HistoryRank = 1
JOIN 
    RankedUsers UsersRank ON u.Id = UsersRank.UserId
WHERE 
    UsersRank.UserRank <= 10
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
