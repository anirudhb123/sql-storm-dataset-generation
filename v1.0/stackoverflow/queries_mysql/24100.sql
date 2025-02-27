
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostEngagement AS (
    SELECT 
        rp.PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastActivity,
        GROUP_CONCAT(DISTINCT pt.Name) AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        pe.Upvotes,
        pe.Downvotes,
        pe.CommentCount,
        phs.HistoryCount,
        phs.LastActivity,
        phs.HistoryTypes,
        CASE 
            WHEN rp.Rank <= 3 THEN 'Top Performers'
            WHEN rp.Rank BETWEEN 4 AND 10 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        PostEngagement pe ON rp.PostId = pe.PostId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Upvotes,
    p.Downvotes,
    p.CommentCount,
    p.HistoryCount,
    p.LastActivity,
    p.HistoryTypes,
    p.EngagementLevel
FROM 
    FinalResults p
WHERE 
    p.CommentCount > (SELECT AVG(CommentCount) FROM FinalResults) 
    AND p.Upvotes IS NOT NULL
ORDER BY 
    p.Upvotes DESC, p.CommentCount DESC
LIMIT 10 OFFSET 10;
