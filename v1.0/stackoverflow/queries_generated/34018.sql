WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserReputationSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithVotes AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, v.VoteTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ClosedDate,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.ClosedDate IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.ClosedDate
)

SELECT 
    u.DisplayName AS User,
    COUNT(DISTINCT q.Id) AS TotalQuestions,
    COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    MAX(CASE WHEN v.VoteTypeId = 2 THEN v.VoteCount ELSE 0 END) AS MaxUpVotes,
    SUM(v.VoteCount) AS TotalVotes, 
    COUNT(DISTINCT cp.Id) AS ClosedPostCount,
    GROUP_CONCAT(DISTINCT CONCAT('Question: ', rp.Title, ' (Level: ', rp.Level, ')') ORDER BY rp.Level) AS QuestionHierarchy
FROM 
    UserReputationSummary u
LEFT JOIN 
    Posts q ON u.UserId = q.OwnerUserId
LEFT JOIN 
    Badges b ON u.UserId = b.UserId
LEFT JOIN 
    PostsWithVotes v ON q.Id = v.Id
LEFT JOIN 
    ClosedPosts cp ON q.Id = cp.Id
LEFT JOIN 
    RecursivePostHierarchy rp ON q.Id = rp.Id
WHERE 
    u.QuestionCount > 0
GROUP BY 
    u.DisplayName
HAVING 
    TotalVotes > 10 AND
    ClosedPostCount > 0
ORDER BY 
    TotalVotes DESC;
