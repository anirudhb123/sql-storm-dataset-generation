WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers,
        COALESCE(SUM(c.Id IS NOT NULL), 0) AS CommentsMade,
        COALESCE(SUM(b.Id IS NOT NULL), 0) AS BadgesEarned,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.CreationDate,
    us.UpVotes,
    us.DownVotes,
    us.QuestionsAsked,
    us.AnswersProvided,
    us.AcceptedAnswers,
    us.CommentsMade,
    us.BadgesEarned,
    us.Rank,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypes,
    ARRAY_AGG(DISTINCT lt.Name) AS LinkTypes
FROM 
    UserStatistics us
LEFT JOIN 
    Posts p ON us.UserId = p.OwnerUserId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE 
    us.Rank <= 10 -- limiting to top 10 users
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.CreationDate, us.UpVotes, us.DownVotes, us.QuestionsAsked, us.AnswersProvided, us.AcceptedAnswers, us.CommentsMade, us.BadgesEarned, us.Rank
ORDER BY 
    us.Rank;
