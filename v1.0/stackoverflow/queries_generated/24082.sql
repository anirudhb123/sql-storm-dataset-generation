WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        COALESCE(ph.UserId, -1) AS EditorId
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6, 10, 11)
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
QuestionStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.ScoreRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = rp.PostId) AS AnswerCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = rp.EditorId) AS EditorBadges
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 3 OR rp.EditorId = -1 -- Top 3 posts or community-edited
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed and Post Reopened
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        qs.*,
        COALESCE(cr.CloseReasonNames, 'No reasons') AS CloseDetails
    FROM 
        QuestionStats qs
    LEFT JOIN 
        CloseReasons cr ON qs.PostId = cr.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    EditorBadges,
    CloseDetails
FROM 
    FinalStats
WHERE 
    (Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) OR CommentCount > 5) -- Above average score or more than 5 comments
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 10
FOR UPDATE SKIP LOCKED; -- Lock selected rows for further updates
