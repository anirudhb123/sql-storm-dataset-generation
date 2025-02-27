WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        EXTRACT(YEAR FROM p.CreationDate) AS PostYear,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '5 years'
),
PostHistoryLatest AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS LatestRevision
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.NetVotes,
        COALESCE(pl.LinkCategory, 'None') AS LinkCategory,
        ph.PostHistoryTypeId
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            STRING_AGG(LinkTypeId::VARCHAR, ', ') AS LinkCategory
        FROM 
            PostLinks
        GROUP BY 
            PostId
    ) pl ON rp.PostId = pl.PostId
    LEFT JOIN PostHistoryLatest ph ON rp.PostId = ph.PostId AND ph.LatestRevision = 1
    WHERE 
        rp.Rank <= 5 -- Top 5 by score per post type
)
SELECT 
    fp.*,
    CASE 
        WHEN fp.PostHistoryTypeId IS NULL THEN 'Active'
        WHEN fp.PostHistoryTypeId IN (10, 12) THEN 'Inactive'
        ELSE 'Previously ' || 
            (SELECT Name FROM PostHistoryTypes WHERE Id = fp.PostHistoryTypeId)
    END AS Status,
    CASE 
        WHEN fp.NetVotes > 10 THEN 'High Engagement'
        WHEN fp.NetVotes <= 10 AND fp.ViewCount > 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CONCAT('Posted on ', TO_CHAR(fp.CreationDate, 'FMMonth FMDD, YYYY')) AS FormattedCreationDate
FROM 
    FilteredPosts fp
WHERE 
    (fp.Score > 0 OR fp.CommentCount > 0) AND 
    (fp.ViewCount BETWEEN 100 AND 10000 OR fp.NetVotes IS NULL)
ORDER BY 
    fp.CreationDate DESC;
