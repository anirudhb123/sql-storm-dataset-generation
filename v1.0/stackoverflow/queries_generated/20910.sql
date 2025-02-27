WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentsCount,
        MAX(v.CreationDate) OVER (PARTITION BY p.Id) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.ViewCount > 100 AND
        (COALESCE(p.CreationDate, '1900-01-01') > '2020-01-01' OR p.Score > 5)
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN ph.CreationDate END) AS DeletedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.ScoreRank,
    phd.ClosedDate,
    phd.ReopenedDate,
    phd.DeletedDate,
    ue.PostsCreated,
    ue.TotalCommentScore,
    ue.UpVotesReceived,
    CASE 
        WHEN rp.LastVoteDate IS NOT NULL THEN 
            (SELECT COUNT(*) 
             FROM Votes v 
             WHERE v.PostId = rp.PostId AND v.CreationDate > rp.LastVoteDate)
        ELSE 0 
    END AS VotesAfterLastAction
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
LEFT JOIN 
    UserEngagement ue ON ue.UserId = rp.OwnerUserId
WHERE 
    (phd.ClosedDate IS NULL OR phd.ReopenedDate IS NOT NULL) AND
    (rp.ScoreRank <= 10 OR rp.ViewCount > 500)
ORDER BY 
    rp.Score DESC, 
    ue.PostsCreated DESC, 
    rp.CreationDate DESC;
