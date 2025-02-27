WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CASE 
            WHEN Score >= 100 THEN 'Hot'
            WHEN Score BETWEEN 50 AND 99 THEN 'Trending'
            ELSE 'New'
        END AS PostCategory
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Top 10 posts by score
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
PostVotes AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes pv
    GROUP BY 
        pv.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.PostCategory,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(phd.LastEditDate, 'Never Edited') AS LastEditDate,
    COALESCE(phd.LastClosedDate, 'Never Closed') AS LastClosedDate
FROM 
    PostStatistics ps
LEFT JOIN 
    PostComments pc ON ps.PostId = pc.PostId
LEFT JOIN 
    PostVotes pv ON ps.PostId = pv.PostId
LEFT JOIN 
    PostHistoryDetails phd ON ps.PostId = phd.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
