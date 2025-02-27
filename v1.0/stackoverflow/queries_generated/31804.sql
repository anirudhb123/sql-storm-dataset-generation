WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > '2022-01-01'
),
RecentActivity AS (
    SELECT 
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEdit,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5)  -- Edit Title & Edit Body
    GROUP BY 
        p.Title
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS ActivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes - rp.DownVotes AS NetVotes,
    ra.EditCount,
    ra.LastEdit,
    ua.UserId,
    ua.DisplayName,
    ua.ActivePostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivity ra ON rp.Title = ra.Title
LEFT JOIN 
    ActiveUsers ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.RN = 1  -- get the latest post per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
