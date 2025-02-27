WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(v.VoteTypeId) AS AverageVoteType
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
)

SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.Reputation,
    ru.ReputationRank,
    ru.PostCount,
    ru.AnswerCount,
    ru.QuestionCount,
    ru.AverageVoteType,
    bh.BadgeCount
FROM 
    RankedUsers ru
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) bh ON ru.UserId = bh.UserId
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.Reputation DESC, ru.DisplayName;

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 14 THEN 1 ELSE 0 END), 0) AS ModReviewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.ModReviewCount,
    p.UserDisplayName AS OwnerDisplayName
FROM 
    PostStats ps
JOIN 
    Posts p ON ps.PostId = p.Id
WHERE 
    ps.CommentCount > 0
ORDER BY 
    ps.UpvoteCount DESC, ps.CommentCount DESC;
