WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        pt.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 month'
),
RecentChanges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.Rank,
        ph.PostHistoryType,
        ph.UserDisplayName,
        ph.CreationDate AS ChangeDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryChanges ph ON rp.PostId = ph.PostId
    WHERE 
        rp.Rank <= 10  -- Get top 10 posts by score for each post type
)
SELECT 
    rc.PostId,
    rc.Title,
    rc.Author,
    rc.Rank,
    rc.PostHistoryType,
    rc.UserDisplayName,
    COALESCE(rc.ChangeDate::date, 'No changes') AS LastChangeDate
FROM 
    RecentChanges rc
ORDER BY 
    rc.Rank, rc.PostId;
