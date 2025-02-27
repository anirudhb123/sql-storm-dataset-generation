WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY  
        p.Id, p.Title, p.CreationDate, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        MAX(ph.CreationDate) AS LastClosedDate,
        MIN(ph.CreationDate) AS FirstClosedDate,
        COUNT(*) AS TotalClosureHistory
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened status
    GROUP BY 
        ph.PostId
),
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        COALESCE(cp.LastClosedDate, 'No Closure') AS LastClosed,
        COALESCE(cp.FirstClosedDate, 'No Closure') AS FirstOpened,
        cp.TotalClosureHistory,
        CASE 
            WHEN cp.TotalClosureHistory IS NULL THEN 'Active'
            WHEN cp.TotalClosureHistory > 5 THEN 'Highly Closed'
            ELSE 'Moderately Closed'
        END AS ClosureStatus
    FROM 
        TopPosts tp
    LEFT JOIN 
        ClosedPosts cp ON tp.PostId = cp.PostId
),
FinalResult AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.LastClosed,
        ps.FirstOpened,
        ps.ClosureStatus,
        ur.DisplayName,
        ur.Reputation
    FROM 
        PostStats ps
    LEFT JOIN 
        UserReputation ur ON ur.UserId = (
            SELECT OwnerUserId 
            FROM Posts 
            WHERE Id = ps.PostId
        )
)
SELECT 
    fr.*, 
    CASE 
        WHEN fr.LastClosed IS NULL THEN 'Never Closed'
        WHEN fr.ClosureStatus = 'Active' AND fr.Score > 10 THEN 'Active High Score'
        ELSE 'Needs Attention'
    END AS ActionRecommendation
FROM 
    FinalResult fr
WHERE 
    fr.Reputation > 100 AND 
    (fr.ClosureStatus IS NOT NULL OR fr.ClosureStatus != 'Active')
ORDER BY 
    fr.Reputation DESC, 
    fr.Score DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY; -- Pagination
