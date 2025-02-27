WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(p.Announcement, 'No Announcement') AS Announcement,
        p.OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 10 THEN 'High Score'
            WHEN rp.Score BETWEEN 5 AND 10 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        CASE 
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pt.Name, ', ') AS HistoryTypes
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate IS NOT NULL
    GROUP BY 
        p.Id
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.Score,
    pa.ViewCount,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    pa.ScoreCategory,
    pa.CommentStatus,
    COALESCE(phd.LastEditDate, 'Never Edited') AS LastEditDate,
    CASE 
        WHEN pa.CommentCount > 0 THEN 'Comment Section Active'
        ELSE 'Comment Section Dormant'
    END AS CommentActivity,
    CASE 
        WHEN phd.HistoryTypes LIKE '%Edit Body%' THEN 'Edited Body'
        ELSE 'No Body Edit'
    END AS BodyEditStatus,
    (SELECT COUNT(*) FROM Tags t WHERE t.WikiPostId = pa.PostId) AS AssociatedTagsCount,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = pa.PostId) AS RelatedPostsCount
FROM 
    PostAnalytics pa
LEFT JOIN 
    PostHistoryDetails phd ON pa.PostId = phd.PostId
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC
LIMIT 50;
