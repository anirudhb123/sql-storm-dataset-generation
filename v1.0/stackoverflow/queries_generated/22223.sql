WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*,
        (UpvoteCount - DownvoteCount) AS NetVoteScore,
        CASE 
            WHEN UserPostRank = 1 AND CommentCount > 5 THEN 'Top Contributor'
            WHEN UserPostRank = 1 THEN 'First Post'
            ELSE 'Regular'
        END AS PostStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score >= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        ph.UserDisplayName,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            ELSE 'Other' 
        END AS ActionType
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.NetVoteScore,
        tp.PostStatus,
        COALESCE(ph.UserDisplayName, 'N/A') AS LastActionUser,
        COALESCE(ph.ActionType, 'No Actions') AS LastActionType,
        COUNT(DISTINCT ph.Comment) AS HistoryComments
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostHistoryDetails ph ON tp.PostId = ph.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.NetVoteScore, tp.PostStatus, ph.UserDisplayName, ph.ActionType
)
SELECT 
    *,
    CASE 
        WHEN HistoryComments > 0 THEN 'Has History'
        ELSE 'No History'
    END AS HistoryStatus,
    CASE 
        WHEN Score IS NOT NULL THEN 'Score Present'
        ELSE 'No Score'
    END AS ScorePresence,
    COALESCE((SELECT COUNT(*) FROM Posts WHERE Tags LIKE CONCAT('%', tp.Title, '%')), 0) AS RelatedQuestionsCount
FROM 
    FinalResults tp
ORDER BY 
    NetVoteScore DESC, Score DESC
LIMIT 50;
