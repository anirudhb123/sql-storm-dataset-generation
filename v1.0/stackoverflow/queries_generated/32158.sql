WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId = 2) AS AverageUpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > DATEADD(year, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
),
BonusBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class IS NOT NULL
    GROUP BY 
        u.Id
    HAVING 
        SUM(b.Class) > 2 -- Only consider users with more than 2 badge score
),
CompletedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Rank,
        rp.CommentCount,
        rp.ViewCount,
        rp.AverageUpVotes,
        rph.LastEditDate,
        rph.EditComments,
        bb.TotalBadgeScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
    LEFT JOIN 
        BonusBadges bb ON rp.OwnerDisplayName = bb.UserId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.OwnerDisplayName,
    cp.CommentCount,
    cp.ViewCount,
    cp.AverageUpVotes,
    cp.LastEditDate,
    cp.EditComments,
    COALESCE(cp.TotalBadgeScore, 0) AS BadgeScore
FROM 
    CompletedPosts cp
ORDER BY 
    cp.ViewCount DESC, cp.AverageUpVotes DESC;

