WITH UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'N/A' 
            WHEN u.Reputation < 1000 THEN 'Novice' 
            WHEN u.Reputation BETWEEN 1000 AND 4999 THEN 'Intermediate' 
            WHEN u.Reputation >= 5000 THEN 'Expert' 
        END AS ReputationLevel,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                            WHEN u.Reputation IS NULL THEN 'N/A' 
                                            WHEN u.Reputation < 1000 THEN 'Novice' 
                                            WHEN u.Reputation BETWEEN 1000 AND 4999 THEN 'Intermediate' 
                                            WHEN u.Reputation >= 5000 THEN 'Expert' 
                                         END 
                           ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),

PostSummaryCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        p.CreationDate,
        p.LastActivityDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- closed or reopened
    GROUP BY 
        ph.PostId
),

FinalReport AS (
    SELECT 
        p.Title,
        us.ReputationLevel,
        us.Rank,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.AnswerCount,
        ps.CreationDate,
        ps.LastActivityDate,
        cr.CloseReasonCount,
        cr.CloseReasonNames
    FROM 
        PostSummaryCTE ps
    LEFT JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        UserScoreCTE us ON us.UserId = u.Id
    LEFT JOIN 
        ClosedPosts cr ON cr.PostId = ps.PostId
)

SELECT 
    *
FROM 
    FinalReport
WHERE 
    (CloseReasonCount IS NULL OR CloseReasonCount < 3) -- filter to select posts with fewer than 3 close reasons
    AND ReputationLevel IS NOT NULL 
ORDER BY 
    AnswerCount DESC, 
    ViewCount DESC, 
    LastActivityDate DESC;
