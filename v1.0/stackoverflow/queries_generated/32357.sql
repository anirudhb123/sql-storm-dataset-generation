WITH RecursivePostHierarchy AS (
    -- CTE to retrieve all answers and their ancestors for a given post
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
         
    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.AnswerCount,
        a.ViewCount,
        r.Level + 1 AS Level
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2  -- Only answers
),
RankedPosts AS (
    -- CTE to rank posts based on views and votes
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.Score DESC) AS ViewRank,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
),
PostDetails AS (
    -- CTE to aggregate post and vote information
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.Id) AS HistoryItemCount
    FROM 
        RecursivePostHierarchy r
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Badges b ON r.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON r.PostId = ph.PostId
    GROUP BY 
        r.PostId, r.Title, r.CreationDate
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.BadgeCount,
    rp.ViewRank,
    rp.ScoreRank,
    CASE 
        WHEN pd.UpVotes IS NULL THEN 'No votes' 
        WHEN pd.UpVotes > 50 THEN 'High engagement' 
        ELSE 'Moderate engagement' 
    END AS EngagementLevel,
    DATEDIFF(DAY, pd.CreationDate, GETDATE()) AS AgeInDays
FROM 
    PostDetails pd
JOIN 
    RankedPosts rp ON pd.PostId = rp.Id
WHERE 
    pd.CommentCount > 0  -- Only posts with comments
ORDER BY 
    pd.UpVotes DESC, pd.DownVotes ASC;
