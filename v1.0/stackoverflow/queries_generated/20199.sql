WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -2, GETDATE()) 
        AND p.ViewCount > 1000
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerDisplayName
    GROUP BY 
        rp.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    ps.PostId,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ISNULL(cp.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment,
    CONCAT('Post: ', rp.Title, ' | Score: ', rp.Score) AS PostDetails
FROM 
    PostStatistics ps
JOIN 
    RankedPosts rp ON ps.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.CommentCount > 5 
    AND rp.Rank <= 10
ORDER BY 
    Sentiment ASC, 
    ps.CommentCount DESC;
