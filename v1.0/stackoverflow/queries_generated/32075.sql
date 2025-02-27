WITH RecursivePostHierarchy AS (
    -- CTE to create a hierarchy of questions and their accepted answers
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),

UserVotesCount AS (
    -- CTE to count upvotes and downvotes per user
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

PostCommentStats AS (
    -- CTE to get statistics on comments per post
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),

PostHistoryTypesWithCount AS (
    -- CTE to count the types of post history records for each post
    SELECT 
        ph.PostId,
        pht.Name AS PostHistoryTypeName,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, pht.Name
)

SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    up.UpVotes,
    ud.DownVotes,
    pcs.CommentCount,
    pcs.LastCommentDate,
    rph.Level AS AnswerLevel,
    COALESCE(SUM(CASE WHEN phtc.PostHistoryTypeName = 'Post Closed' THEN phc.HistoryCount END), 0) AS ClosedCount,
    COALESCE(SUM(CASE WHEN phtc.PostHistoryTypeName = 'Edit Body' THEN phc.HistoryCount END), 0) AS EditBodyCount,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserVotesCount up ON u.Id = up.UserId
LEFT JOIN 
    UserVotesCount ud ON u.Id = ud.UserId
LEFT JOIN 
    PostCommentStats pcs ON p.Id = pcs.PostId
LEFT JOIN 
    RecursivePostHierarchy rph ON p.Id = rph.PostId
LEFT JOIN 
    PostHistoryTypesWithCount phc ON p.Id = phc.PostId
LEFT JOIN 
    PostHistoryTypes phtc ON phc.PostHistoryTypeName = phtc.Name
GROUP BY 
    p.Id, u.DisplayName, up.UpVotes, ud.DownVotes, pcs.CommentCount, pcs.LastCommentDate, rph.Level
ORDER BY 
    p.Title ASC;
