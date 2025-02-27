
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ViewCount IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerUserId,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        GROUP_CONCAT(DISTINCT tag.TagName) AS Tags
    FROM 
        TopPosts tp
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (8, 9) 
    LEFT JOIN 
        (SELECT 
            p.Id AS PostId, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
          FROM 
            Posts p
          JOIN 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
          ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) tag ON tp.PostId = tag.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.CommentCount
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close/Reopen Event'
            ELSE 'Other Event'
        END AS EventType,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS MostRecentEventDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 30 DAY
)
SELECT 
    pd.Title, 
    pd.Score, 
    pd.CommentCount,
    pd.TotalBounty,
    pd.Tags,
    SUM(CASE WHEN rph.EventType = 'Close/Reopen Event' THEN 1 ELSE 0 END) AS CloseReopenCount,
    CASE 
        WHEN MAX(rph.MostRecentEventDate) IS NULL THEN 'No recent activity'
        WHEN MAX(rph.MostRecentEventDate) < NOW() - INTERVAL 7 DAY THEN 'Inactive'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostDetails pd
LEFT JOIN 
    RecentPostHistory rph ON pd.PostId = rph.PostId
GROUP BY 
    pd.Title, pd.Score, pd.CommentCount, pd.TotalBounty, pd.Tags
ORDER BY 
    pd.Score DESC, pd.CommentCount DESC
LIMIT 50;
