WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.PostTypeId,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId, p.CreationDate
),
HighScorePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts) 
        AND rp.PostRank <= 5
),
PostDetails AS (
    SELECT 
        p.*,
        COALESCE(CAST(b.Id AS INT), -1) AS BadgeCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(NULLIF(SUBSTRING_INDEX(Body, ' ', 10), ''), 'No content available') AS Preview,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        Posts p
        LEFT JOIN (
            SELECT 
                UserId, COUNT(*) AS Id 
            FROM 
                Badges 
            GROUP BY 
                UserId
        ) b ON p.OwnerUserId = b.UserId
),
FinalResult AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.CommentCount,
        pd.BadgeCount,
        pd.UpVotes,
        pd.Preview,
        pd.AnswerStatus
    FROM 
        PostDetails pd
    WHERE 
        pd.PostId IN (SELECT PostId FROM HighScorePosts)
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.CommentCount IS NULL THEN 'No Comments Yet'
        ELSE CONCAT(fr.CommentCount, ' Comments')
    END AS CommentMessage,
    COALESCE(
        (SELECT SUM(VoteAmount) FROM (SELECT 
            CASE WHEN VoteTypeId = 2 THEN 1 
                 WHEN VoteTypeId = 3 THEN -1 
                 ELSE 0 
            END AS VoteAmount 
        FROM Votes v WHERE v.PostId = fr.PostId) AS VoteSum),
    'No Votes') AS TotalVoteScore
FROM 
    FinalResult fr
ORDER BY 
    fr.Score DESC, fr.PostId;
