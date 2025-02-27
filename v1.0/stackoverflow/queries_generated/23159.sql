WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS rn,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>') AS tagArray ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagArray
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, p.CreationDate, p.ViewCount, p.Score
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5
    AND EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2 -- UpMod
    )
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.Amount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            UserId,
            COUNT(*) AS Amount
         FROM Votes
         WHERE VoteTypeId = 8 -- BountyStart
         GROUP BY UserId) v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), CombinedResult AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.Tags,
        us.DisplayName AS UserName,
        us.BadgeCount,
        us.TotalBounties,
        CASE 
            WHEN us.TotalBounties IS NULL THEN 'No Bounties'
            ELSE 'Bounties Available'
        END AS BountyStatus
    FROM 
        FilteredPosts fp
    JOIN 
        Users u ON fp.ViewCount > 100 -- Including popular posts
    LEFT JOIN 
        UserStats us ON u.Id = fp.OwnerUserId
)
SELECT 
    cr.PostId,
    cr.Title,
    cr.CreationDate,
    cr.ViewCount,
    cr.Score,
    cr.Tags,
    cr.UserName,
    cr.BadgeCount,
    cr.TotalBounties,
    cr.BountyStatus
FROM 
    CombinedResult cr
WHERE 
    (cr.Score > 5 OR cr.BountyStatus = 'Bounties Available')
ORDER BY 
    cr.Score DESC, cr.ViewCount DESC, cr.CreationDate DESC;
