
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
), 
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ISNULL(b.Class, 0)) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id, u.DisplayName
), 
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    au.DisplayName AS OwnerDisplayName,
    au.TotalBadges,
    au.PostCount,
    pa.CommentCount,
    pa.CloseCount,
    pa.EditCount
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.OwnerUserId = au.UserId
JOIN 
    PostActivity pa ON rp.PostId = pa.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
