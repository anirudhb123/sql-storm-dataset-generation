WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        1 AS Level,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        CASE 
            WHEN p.ParentId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAnswer,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1),
        Level + 1,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        CASE 
            WHEN p.ParentId IS NOT NULL THEN 1 
            ELSE 0 
        END,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2),
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3)
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostStats r ON r.AcceptedAnswerId = p.Id
)

SELECT
    p.Title,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.Score) AS MedianScore
FROM 
    RecursivePostStats p
LEFT JOIN 
    Comments c ON c.PostId = p.PostId
LEFT JOIN 
    Votes v ON v.PostId = p.PostId
LEFT JOIN 
    Badges b ON b.UserId = p.OwnerUserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Title
ORDER BY 
    MedianScore DESC
LIMIT 10;
