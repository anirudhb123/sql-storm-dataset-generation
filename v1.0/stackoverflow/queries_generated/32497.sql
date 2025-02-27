WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.PostTypeId,
        p.CreationDate,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Base case: only questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        p2.PostTypeId,
        p2.CreationDate,
        rp.Level + 1
    FROM Posts p2
    INNER JOIN RecursivePosts rp ON p2.ParentId = rp.Id  -- Recursive case: linking answers back to their questions
),
PostScores AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id
),
PostSummary AS (
    SELECT 
        rp.Id AS QuestionId,
        rp.Title AS QuestionTitle,
        rp.CreationDate AS QuestionDate,
        ps.VoteCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.UpVotes - ps.DownVotes AS Score,
        u.DisplayName AS OwnerDisplayName
    FROM RecursivePosts rp
    LEFT JOIN PostScores ps ON rp.Id = ps.PostId
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
)
SELECT 
    ps.QuestionId,
    ps.QuestionTitle,
    ps.OwnerDisplayName,
    ps.QuestionDate,
    ps.VoteCount,
    ps.Score,
    RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
FROM PostSummary ps
WHERE ps.Score > 0  -- Only considering questions with positive scores
  AND ps.QuestionDate >= NOW() - INTERVAL '1 year'  -- For the past year
ORDER BY ps.Score DESC, ps.QuestionDate DESC
LIMIT 10;  -- Get top 10 questions
