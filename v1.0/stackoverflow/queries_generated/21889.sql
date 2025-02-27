WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS EffectiveAcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),

ExtendedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        CAST(SUBSTRING(ph.Text, 1, 50) AS VARCHAR(50)) AS ShortText,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            WHEN ph.PostHistoryTypeId = 13 THEN 'Undeleted'
            ELSE 'Other'
        END AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '3 months'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    mp.CommentCount,
    uh.DisplayName,
    uh.TotalUpVotes,
    uh.TotalDownVotes,
    CASE 
        WHEN eh.HistoryRank <= 5 THEN 'Recent Activity'
        ELSE 'Older Activity'
    END AS ActivityType,
    STRING_AGG(pt.Name, ', ') AS PostTypeNames,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    MostCommentedPosts mp ON rp.PostId = mp.PostId
JOIN 
    UserStats uh ON rp.EffectiveAcceptedAnswerId = uh.UserId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostTypes pt ON rp.PostTypeId = pt.Id
LEFT JOIN 
    ExtendedPostHistory eh ON rp.PostId = eh.PostId AND eh.HistoryType = 'Closed/Reopened'
WHERE 
    rp.ViewCount > 100
    AND (uh.TotalUpVotes - uh.TotalDownVotes) > 50
GROUP BY 
    rp.PostId, rp.Title, rp.Score, mp.CommentCount, uh.DisplayName, uh.TotalUpVotes, uh.TotalDownVotes, eh.HistoryRank
ORDER BY 
    rp.Score DESC, mp.CommentCount DESC, rp.CreationDate DESC
LIMIT 100;
