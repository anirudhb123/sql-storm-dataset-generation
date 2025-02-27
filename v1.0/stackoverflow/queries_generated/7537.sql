WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownVotes,
        COUNT(DISTINCT bh.Id) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        us.DisplayName AS OwnerDisplayName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        us.TotalBadges,
        us.TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        UserScore us ON rp.PostId = us.UserId
)
SELECT 
    pa.OwnerDisplayName,
    pa.Title,
    pa.CreationDate,
    pa.ViewCount,
    pa.Score,
    pa.TotalUpVotes,
    pa.TotalDownVotes,
    pa.TotalBadges,
    pa.TotalComments
FROM 
    PostActivity pa
WHERE 
    pa.Score > 10
ORDER BY 
    pa.ViewCount DESC, pa.Score DESC
LIMIT 100;
