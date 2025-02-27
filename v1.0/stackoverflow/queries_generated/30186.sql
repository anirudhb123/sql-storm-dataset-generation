WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.ParentId,
        p.CreationDate,
        0 AS Depth
    FROM
        Posts p
    WHERE
        p.ParentId IS NULL

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Depth + 1
    FROM
        Posts p
    INNER JOIN
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
TopQuestions AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Only Questions
)
SELECT
    q.Id AS QuestionId,
    q.Title AS QuestionTitle,
    q.CreationDate AS QuestionDate,
    u.DisplayName AS OwnerName,
    u.TotalReputation,
    u.BadgeCount,
    ph.Depth AS RelatedPostsDepth,
    COALESCE(ph.PostId, -1) AS RelatedPostId
FROM
    TopQuestions q
JOIN
    UserReputation u ON q.OwnerUserId = u.UserId
LEFT JOIN
    RecursivePostHierarchy ph ON q.Id = ph.ParentId
WHERE
    q.ScoreRank <= 10  -- Top 10 questions by score
ORDER BY
    q.Score DESC,
    u.TotalReputation DESC;

-- Adding a layer to determine the users who have upvoted or downvoted these questions
WITH VotesSummary AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Votes v
    GROUP BY
        v.PostId
)
SELECT
    q.QuestionId,
    q.QuestionTitle,
    q.QuestionDate,
    q.OwnerName,
    q.TotalReputation,
    q.BadgeCount,
    q.RelatedPostsDepth,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes
FROM
    (
        SELECT
            QuestionId,
            QuestionTitle,
            QuestionDate,
            OwnerName,
            TotalReputation,
            BadgeCount,
            MAX(RelatedPostsDepth) AS RelatedPostsDepth
        FROM
            (
                SELECT
                    q.Id AS QuestionId,
                    q.Title AS QuestionTitle,
                    q.CreationDate AS QuestionDate,
                    u.DisplayName AS OwnerName,
                    u.TotalReputation,
                    u.BadgeCount,
                    ph.Depth AS RelatedPostsDepth
                FROM
                    TopQuestions q
                JOIN
                    UserReputation u ON q.OwnerUserId = u.UserId
                LEFT JOIN
                    RecursivePostHierarchy ph ON q.Id = ph.ParentId
            ) AS SubQuery
        GROUP BY
            QuestionId, QuestionTitle, QuestionDate, OwnerName, TotalReputation, BadgeCount
    ) AS q
LEFT JOIN
    VotesSummary vs ON q.QuestionId = vs.PostId
ORDER BY
    q.TotalReputation DESC;
