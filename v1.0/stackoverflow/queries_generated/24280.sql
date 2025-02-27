WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount > 5 THEN 'High Engagement'
            WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderate Engagement'
            ELSE 'No Engagement' 
        END AS EngagementLevel,
        CASE 
            WHEN rp.AcceptedAnswerId = -1 THEN 'Unanswered'
            ELSE 'Answered'
        END AS AnswerStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.UpVoteCount > 10 AND rp.DownVoteCount = 0
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
FinalResults AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.EngagementLevel,
        fp.AnswerStatus,
        ph.HistoryType,
        ph.HistoryDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistoryDetails ph ON fp.PostId = ph.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.EngagementLevel,
    fr.AnswerStatus,
    COALESCE(fr.HistoryType, 'No Recent History') AS RecentHistoryType,
    COALESCE(fr.HistoryDate, 'N/A') AS RecentHistoryDate
FROM 
    FinalResults fr
ORDER BY 
    fr.CreationDate DESC
LIMIT 100;
