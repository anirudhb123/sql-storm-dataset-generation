WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE((SELECT SUM(VoteTypeId = 2) FROM Votes WHERE PostId = p.Id), 0) AS UpVotes,
        COALESCE((SELECT SUM(VoteTypeId = 3) FROM Votes WHERE PostId = p.Id), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostHistories AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId
),
TopPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        ph.FirstEditDate,
        ph.EditCount,
        CASE 
            WHEN ph.EditCount > 3 THEN 'Frequent Edits'
            WHEN ph.EditCount BETWEEN 1 AND 3 THEN 'Infrequent Edits'
            ELSE 'No Edits'
        END AS EditFrequency,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn <= 10 -- Getting top 10 posts per group based on rank
)
SELECT 
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.EditFrequency,
    ps.FirstEditDate,
    ROUND(PS.Score::decimal / NULLIF(ps.EditCount, 0), 2) AS ScorePerEdit,
    CASE
        WHEN ps.FirstEditDate IS NULL THEN 'Never Edited'
        ELSE 'Edited'
    END AS EditStatus
FROM 
    TopPostStats ps
WHERE 
    ps.NetVotes >= 5 AND -- Filter for posts with a positive net vote count
    (ps.EditFrequency = 'Frequent Edits' OR ps.EditFrequency = 'No Edits') -- Bizarre behavior: focus on frequently edited posts
ORDER BY 
    ps.Score DESC,
    ps.CreationDate DESC;

This query extracts and ranks the top 10 questions from the past year based on their score and examines their edit histories, offering insights into engagement through edits. It utilizes CTEs to breakdown the data, includes various predicates and computations for performance benchmarking, and highlights unusual edge cases around edit behavior.
