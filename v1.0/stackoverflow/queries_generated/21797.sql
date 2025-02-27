WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) 
                  FROM Votes v WHERE v.PostId = p.Id), 0) AS UpvoteCount,
        COALESCE((SELECT SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) 
                  FROM Votes v WHERE v.PostId = p.Id), 0) AS DownvoteCount,
        (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.Id 
         AND ph.PostHistoryTypeId = 10) AS CloseVoteCount
    FROM 
        Posts p
    WHERE 
        p.ViewCount > 100
),

MostCommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.ViewCount,
        rp.Score
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
        AND rp.CommentCount > (SELECT AVG(CommentCount) FROM RankedPosts)
),

PostDetails AS (
    SELECT 
        mp.PostId,
        mp.Title,
        mp.CommentCount,
        mp.ViewCount,
        mp.Score,
        mp.CloseVoteCount,
        (CASE 
            WHEN mp.CloseVoteCount > 0 THEN 'Closed'
            ELSE 'Open'
         END) AS PostStatus
    FROM 
        MostCommentedPosts mp
)

SELECT 
    pd.Title,
    pd.ViewCount,
    pd.CommentCount,
    pd.Score,
    pd.PostStatus,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><'))
                           FROM Posts p WHERE p.Id = pd.PostId)
    ) AS Tags,
    (SELECT COUNT(*) 
     FROM Badges b 
     WHERE b.UserId IN (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = pd.PostId) 
     AND b.Class = 1) AS GoldBadgeCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC NULLS LAST
LIMIT 10;
