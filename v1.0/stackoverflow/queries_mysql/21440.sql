
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@current_partition = pt.Name, @row_number + 1, 1) AS ScoreRank,
        @current_partition := pt.Name,
        COALESCE(COUNT(v.Id) * (v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(COUNT(v.Id) * (v.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(
            (SELECT COUNT(c.Id) 
             FROM Comments c 
             WHERE c.PostId = p.Id AND c.CreationDate >= (NOW() - INTERVAL 30 DAY)), 0
        ) AS RecentComments
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_partition := '') AS vars
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(ph.Comment SEPARATOR '; ') AS CommentsAggregate,
        MAX(ph.CreationDate) AS LastUpdate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
AggregatedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.ScoreRank,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.RecentComments,
        phi.CommentsAggregate,
        phi.LastUpdate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryInfo phi ON rp.PostId = phi.PostId
)
SELECT 
    ad.*,
    CASE 
        WHEN ad.ScoreRank = 1 THEN 'Top Post'
        WHEN ad.Score < 10 AND ad.RecentComments > 0 THEN 'Needs Attention'
        ELSE 'Average Post'
    END AS PostStatus,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = ad.PostId AND v.VoteTypeId = 1) THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    NULLIF(ad.CommentsAggregate, '') AS CommentDetails
FROM 
    AggregatedData ad
WHERE 
    ad.RecentComments > 5 OR ad.UpVoteCount > 20
ORDER BY 
    ad.Score DESC, ad.RecentComments DESC
LIMIT 50;
