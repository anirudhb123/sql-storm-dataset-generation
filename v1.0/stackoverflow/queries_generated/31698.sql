WITH RecursiveFlaggedPosts AS (
    -- Get all posts flagged for closure
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS LastFlagDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS FlagCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
PostDetails AS (
    -- Combine flagged posts with user details and vote counts
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastFlagDate,
        COUNT(v.Id) AS VoteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COALESCE(p.Score, 0) AS PostScore,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        RecursiveFlaggedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.LastFlagDate, u.DisplayName, u.Reputation, p.Score
),
RankedPosts AS (
    -- Ranking posts based on vote count and score
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY VoteCount DESC, PostScore DESC) AS PostRank
    FROM 
        PostDetails pd
),
TopFlaggedPosts AS (
    -- Get the top flagged posts for additional analysis
    SELECT 
        *,
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation User'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation User'
            ELSE 'Low Reputation User'
        END AS ReputationCategory
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
)
-- Final Selection
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.LastFlagDate,
    t.VoteCount,
    t.OwnerDisplayName,
    t.Reputation,
    t.PostScore,
    t.AnswerStatus,
    t.ReputationCategory,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    MAX(t.PostRank) OVER () AS HighestRank
FROM 
    TopFlaggedPosts t
LEFT JOIN 
    (SELECT 
         PostId, COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY 
         PostId) c ON t.PostId = c.PostId
ORDER BY 
    t.PostRank;

