WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Pending' 
        END AS AnswerStatus
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostVotes AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    rp.AnswerStatus,
    CASE 
        WHEN rp.Score > 100 THEN 'High Scoring'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50
OFFSET 0;

-- Additional filtering for bizarre cases: 
SELECT
    *,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = rp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    (SELECT STRING_AGG(DISTINCT pt.Name, ', ') 
     FROM PostHistory ph JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id 
     WHERE ph.PostId = rp.PostId) AS HistoryTypes
FROM 
    RankedPosts rp
WHERE 
    rp.CreationDate < (SELECT MAX(CreationDate) FROM Posts)
    AND NOT EXISTS (
        SELECT 1 FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 12 -- Spam votes
    )
ORDER BY 
    rp.PostRank DESC;
