
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes,
        TIMESTAMPDIFF(SECOND, p.CreationDate, '2024-10-01 12:34:56') / 3600 AS AgeInHours,
        COALESCE((
            SELECT COUNT(c.Id)
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseCount,
        GROUP_CONCAT(DISTINCT ctr.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS UNSIGNED) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AgeInHours,
        rp.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasons, 'None') AS CloseReasons,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.AgeInHours < 24 AND rp.UpVotes = 0 THEN 'New Post with No Upvotes'
            WHEN rp.Score < 0 THEN 'Negative Score'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AgeInHours,
    ps.CommentCount,
    ps.CloseCount,
    ps.CloseReasons,
    ps.UpVotes,
    ps.DownVotes,
    ps.PostCategory
FROM 
    PostStatistics ps
WHERE 
    ps.CloseCount < 1 
    AND ps.AgeInHours < 72 
ORDER BY 
    ps.ViewCount DESC, 
    ps.Score DESC;
