WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsMade,
        COUNT(DISTINCT bh.Id) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        COALESCE(ua.UserDisplayName, 'Community') AS AnsweredBy,
        MAX(v.CreationDate) AS LastVoteDate,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users ua ON a.OwnerUserId = ua.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AcceptedAnswerId, ua.UserDisplayName
)

SELECT 
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersGiven,
    ua.CommentsMade,
    ua.BadgesEarned,
    ps.Title AS MostVotedQuestion,
    ps.ViewCount,
    ps.Score,
    ps.AnsweredBy,
    ps.LastVoteDate,
    ps.TotalVotes
FROM 
    UserActivity ua
JOIN 
    (SELECT 
         *,
         ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY TotalVotes DESC) AS rn
     FROM 
         PostStats) ps ON ua.UserId = ps.AnsweredBy
WHERE 
    ps.rn = 1 
ORDER BY 
    ua.BadgesEarned DESC, ua.QuestionsAsked DESC;
