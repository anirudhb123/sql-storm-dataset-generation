
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(NULLIF(p.AnswerCount, 0), 1) AS AnswerCountAdjusted,
        w.UserReputation
    FROM 
        Posts p
    JOIN (
        SELECT 
            u.Id AS UserId,
            SUM(u.Reputation) AS UserReputation
        FROM 
            Users u
        WHERE 
            u.Reputation > 1000
        GROUP BY u.Location
    ) w ON p.OwnerUserId = w.UserId
    WHERE
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
        AND p.PostTypeId IN (1, 2) 
),
PostVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.PostId
),
PostComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY c.PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.PostTypeId,
    rp.PostRank,
    pv.UpVoteCount,
    pv.DownVoteCount,
    pc.CommentCount,
    phs.HistoryTypes,
    phs.HistoryCount,
    CASE 
        WHEN pv.UpVoteCount > pv.DownVoteCount THEN 'Positive'
        WHEN pv.UpVoteCount < pv.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN rp.AnswerCountAdjusted IS NULL THEN 'No Answers Yet'
        WHEN rp.AnswerCountAdjusted > 10 THEN 'Highly Answered'
        ELSE 'Moderately Answered'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.PostRank <= 10
    AND EXISTS (
        SELECT 1 
        FROM Posts p2 
        WHERE p2.AcceptedAnswerId = rp.PostId
    )
ORDER BY 
    rp.PostRank, rp.CreationDate DESC;
