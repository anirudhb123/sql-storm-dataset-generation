WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        a.CreationDate,
        a.Score,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.Id
)
SELECT 
    p.Title AS QuestionTitle,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(p.Score, 0) AS QuestionScore,
    COALESCE(a.Score, 0) AS AnswerScore,
    COALESCE(badgeCount.BadgeCount, 0) AS BadgeCount,
    COALESCE(voteCount.VoteCount, 0) AS TotalVotes,
    ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY COALESCE(a.Score, 0) DESC) AS AnswerRank
FROM 
    RecursivePostCTE p
LEFT JOIN 
    Posts a ON p.Id = a.ParentId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) badgeCount ON u.Id = badgeCount.UserId
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
) voteCount ON p.Id = voteCount.PostId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
AND 
    p.Score > 0
ORDER BY 
    p.Score DESC, COALESCE(a.Score, 0) DESC;
