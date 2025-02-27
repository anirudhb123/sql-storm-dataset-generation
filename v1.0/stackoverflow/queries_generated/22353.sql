WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(b.Id) > 5 -- Users with more than 5 badges
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        (CASE 
            WHEN rp.CommentCount IS NULL THEN 'No Comments'
            ELSE 'Has Comments'
        END) AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason,
        p.Title AS PostTitle,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    pp.CommentCount,
    pu.DisplayName AS Owner,
    pu.Reputation,
    CASE 
        WHEN ph.CloseReason IS NOT NULL THEN ph.CloseReason 
        ELSE 'Open'
    END AS PostStatus,
    STRING_AGG(DISTINCT CONCAT(CAST(rp.CommentStatus AS VARCHAR), ' (', rp.CommentCount, ' comments)')) AS StatusSummary
FROM 
    PopularPosts pp
JOIN 
    TopUsers pu ON pp.CommentCount > 0 -- Only include users with comments on their posts
LEFT JOIN 
    PostHistoryDetails ph ON pp.PostId = ph.PostId AND ph.HistoryRank = 1
GROUP BY 
    pp.PostId, pp.Title, pp.ViewCount, pp.Score, pp.CommentCount, pu.DisplayName, pu.Reputation, ph.CloseReason
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC, pp.CommentCount DESC
OPTION (MAXDOP 4); -- To limit parallelism for performance testing
