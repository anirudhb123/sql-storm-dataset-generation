WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        0 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostId IS NOT NULL
    UNION ALL
    SELECT 
        ph.Id,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory rph ON ph.PostId = rph.PostId
    WHERE 
        rph.Level < 5
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AnswerCount,
        p.ClosedDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(B.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '90 days'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM 
        PostDetails pd
),
VoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerUserId,
    rp.AnswerCount,
    rp.CommentCount,
    rv.UpVotes,
    rv.DownVotes,
    rp.ClosedDate,
    ph.Comment AS LastEditComment,
    ph.CreationDate AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteSummary rv ON rp.PostId = rv.PostId
LEFT JOIN 
    (SELECT 
        MAX(CreationDate) AS MaxDate,
        PostId,
        Comment
     FROM 
        RecursivePostHistory
     WHERE 
        PostHistoryTypeId IN (10, 11, 12)  -- Closed and deleted posts
     GROUP BY 
        PostId, Comment
    ) ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank <= 50
ORDER BY 
    rp.PostRank;
