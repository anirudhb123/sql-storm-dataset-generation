WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.CreationDate >= NOW() - INTERVAL '1 year'
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.PostTypeId,
        rp.ScoreRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.ScoreRank BETWEEN 1 AND 5 THEN 'Top Score'
            WHEN rp.ScoreRank BETWEEN 6 AND 15 THEN 'Moderate Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        CASE 
            WHEN rp.CommentCount IS NULL THEN 'No Comments'
            WHEN rp.CommentCount = 0 THEN 'Zero Comments'
            ELSE 'Has Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > 10
        AND rp.Score IS NOT NULL
),
FinalResults AS (
    SELECT 
        fp.*,
        COALESCE(SUM(b.Class), 0) AS BadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON fp.PostId = b.UserId
    GROUP BY 
        fp.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.ViewCount,
    fr.CreationDate,
    fr.PostTypeId,
    fr.ScoreRank,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.ScoreCategory,
    fr.CommentStatus,
    fr.BadgeCount,
    CASE
        WHEN fr.ViewCount IS NULL THEN 'Unviewed'
        WHEN fr.ViewCount > 100 THEN 'Highly Viewed'
        ELSE 'Moderately Viewed'
    END AS ViewStatus,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    FinalResults fr
LEFT JOIN 
    PostLinks pl ON fr.PostId = pl.PostId
GROUP BY 
    fr.PostId, fr.Title, fr.Score, fr.ViewCount, fr.CreationDate, fr.PostTypeId, 
    fr.ScoreRank, fr.CommentCount, fr.UpVotes, fr.DownVotes, fr.ScoreCategory, 
    fr.CommentStatus, fr.BadgeCount
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 50;
