WITH RECURSIVE PostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        1 AS Level
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 -- Selecting questions only
    UNION ALL
    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.OwnerUserId,
        COALESCE(a.AnswerCount, 0),
        Level + 1
    FROM 
        Posts a 
    INNER JOIN 
        PostCTE q ON a.ParentId = q.PostId -- Recursive join to get answers to questions
    WHERE 
        a.PostTypeId = 2 -- Selecting answers only
),
RankedPosts AS (
    SELECT 
        c.PostId,
        c.Title,
        c.CreationDate,
        c.OwnerUserId,
        c.AnswerCount,
        COUNT(*) OVER (PARTITION BY c.OwnerUserId) AS UserPostCount,
        ROW_NUMBER() OVER (PARTITION BY c.OwnerUserId ORDER BY c.CreationDate DESC) AS UserPostRank
    FROM 
        PostCTE c
),
CommentsWithVotes AS (
    SELECT 
        co.PostId,
        COUNT(co.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Comments co
    LEFT JOIN 
        Votes v ON co.PostId = v.PostId
    GROUP BY 
        co.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate AS QuestionDate,
    u.DisplayName AS OwnerDisplayName,
    p.AnswerCount,
    rp.UserPostCount,
    rp.UserPostRank,
    COALESCE(cv.CommentCount, 0) AS TotalComments,
    COALESCE(cv.UpVoteCount, 0) AS TotalUpVotes,
    COALESCE(cv.DownVoteCount, 0) AS TotalDownVotes,
    CASE 
        WHEN p.AnswerCount > 0 THEN 'Has Answers'
        WHEN p.AnswerCount = 0 AND p.CreationDate <= NOW() - INTERVAL '30 days' THEN 'Unanswered for over 30 days'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts rp
INNER JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    CommentsWithVotes cv ON p.Id = cv.PostId
WHERE 
    (rp.UserPostCount > 5 OR rp.UserPostRank <= 3) -- Users with more than 5 posts or top 3 most recent posts
    AND p.CreationDate > NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
ORDER BY 
    p.CreationDate DESC, 
    p.AnswerCount DESC;
