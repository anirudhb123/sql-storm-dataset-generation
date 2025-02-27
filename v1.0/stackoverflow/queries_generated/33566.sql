WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(h.CreationDate) AS MostRecentEdit
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes h ON ph.PostHistoryTypeId = h.Id
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        p.Title,
        COALESCE(ph.HistoryCount, 0) AS HistoryCount,
        RANK() OVER (ORDER BY (ps.UpVotes - ps.DownVotes) DESC) AS Rank
    FROM 
        PostStats ps
    LEFT JOIN 
        PostHistoryAggregates ph ON ps.PostId = ph.PostId
    INNER JOIN
        Posts p ON ps.PostId = p.Id
),
FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.HistoryCount,
        (rp.UpVotes - rp.DownVotes) AS NetScore,
        CASE 
            WHEN rp.HistoryCount > 0 THEN 'Edited'
            ELSE 'New'
        END AS Status
    FROM 
        RankedPosts rp
)

SELECT 
    fps.PostId,
    fps.Title,
    fps.UpVotes,
    fps.DownVotes,
    fps.CommentCount,
    fps.NetScore,
    fps.Status,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    FinalPostStats fps
LEFT JOIN 
    UNNEST(string_to_array(Posts.Tags, '><')) AS t(TagName) ON fps.PostId = Posts.Id
GROUP BY 
    fps.PostId, fps.Title, fps.UpVotes, fps.DownVotes, fps.CommentCount, fps.NetScore, fps.Status
ORDER BY 
    fps.NetScore DESC
LIMIT 100;
