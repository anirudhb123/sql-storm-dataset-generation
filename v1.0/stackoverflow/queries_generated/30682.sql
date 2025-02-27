WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(cp.FirstCloseDate, 'No Closure') AS ClosureStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.Score > 100 AND rp.Rank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalReport AS (
    SELECT 
        hs.PostId,
        hs.Title,
        hs.Score,
        hs.ViewCount,
        hs.ClosureStatus,
        us.UserId,
        us.DisplayName,
        us.TotalReputation,
        us.PostsCount,
        us.BadgesCount
    FROM 
        HighScoringPosts hs
    JOIN 
        Users u ON hs.PostId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
    JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.ClosureStatus,
    fr.DisplayName AS UserDisplayName,
    fr.TotalReputation,
    fr.PostsCount,
    fr.BadgesCount,
    CASE 
        WHEN fr.ClosureStatus = 'No Closure' THEN 'Active'
        ELSE 'Closed'
    END AS PostStatus
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC
LIMIT 50;
