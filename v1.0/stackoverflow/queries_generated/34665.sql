WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        1 AS Level,
        CAST(p.Title AS VARCHAR(300)) AS Path
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        rp.Level + 1,
        CAST(rp.Path || ' -> ' || p.Title AS VARCHAR(300))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.Id
    WHERE 
        p.PostTypeId = 2 -- Answers only
),
QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title AS QuestionTitle,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        (SELECT COUNT(*) FROM Comments c2 WHERE c2.PostId = p.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edits of title, body, and tags
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
TopQuestions AS (
    SELECT 
        qs.QuestionId,
        qs.QuestionTitle,
        qs.Upvotes - qs.Downvotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY qs.Upvotes DESC) AS Rank
    FROM 
        QuestionStats qs
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpvotesReceived,
        SUM(COALESCE(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
)
SELECT 
    tq.QuestionTitle,
    tq.NetVotes,
    us.DisplayName AS TopUser,
    us.TotalScore,
    COUNT(DISTINCT cp.Id) AS RelatedCommentsCount,
    COUNT(DISTINCT r.Id) AS RecursiveAnswersCount
FROM 
    TopQuestions tq
LEFT JOIN 
    UserScores us ON us.UpvotesReceived = (SELECT MAX(UpvotesReceived) FROM UserScores)
LEFT JOIN 
    Comments cp ON cp.PostId = tq.QuestionId
LEFT JOIN 
    RecursivePostCTE r ON r.ParentId = tq.QuestionId
WHERE 
    tq.Rank <= 10 -- Top 10 Questions
GROUP BY 
    tq.QuestionTitle, tq.NetVotes, us.DisplayName, us.TotalScore
ORDER BY 
    tq.NetVotes DESC;
