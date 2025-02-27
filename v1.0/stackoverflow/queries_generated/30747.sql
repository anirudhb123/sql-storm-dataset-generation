WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        a.Id,
        a.OwnerUserId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.AnswerCount,
        a.CommentCount,
        NULL,
        r.Level + 1
    FROM 
        Posts a
    JOIN 
        RecursivePostCTE r ON a.ParentId = r.Id
    WHERE 
        a.PostTypeId = 2  -- Only answers
), VotesRanked AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (2, 3)  -- Upvotes and Downvotes
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostHistoryWithCloseCount AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(vr.VoteCount, 0) AS TotalVotes,
    ub.BadgeCount,
    p.CloseCount,
    CASE 
        WHEN rp.Score > 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    RecursivePostCTE rp
LEFT JOIN (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE -1 END) AS VoteCount 
    FROM 
        Votes 
    GROUP BY 
        PostId
) vr ON rp.Id = vr.PostId
LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN PostHistoryWithCloseCount p ON rp.Id = p.PostId
WHERE 
    (rp.CreationDate > CURRENT_DATE - INTERVAL '1 year') 
    AND (rp.Score IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;

